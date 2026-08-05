import { v } from "convex/values";
import { action, internalMutation, query } from "./_generated/server.js";
import type { GenericActionCtx } from "convex/server";
import type { DataModel } from "./_generated/dataModel.js";
import { api, internal } from "./_generated/api.js";
import { getSignedUploadUrl, getObjectBytes, getPublicUrl } from "./lib/r2.js";

const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const NAME_PROMPT = `You are naming a cat in a real-world cat-spotting mobile game.
Look at this PNG image of a cat (background already removed).
Give this specific cat a single charming name that suits its appearance, color, and vibe.
Output ONLY the name — one word, max 12 characters, capitalized. No quotes, no punctuation, no explanation.
Examples: Mochi, Shadow, Biscuit, Marmalade, Bean, Whisker, Patches, Goose, Pretzel`;

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Missing Convex env: ${key}`);
  return value;
}

async function requireUser(ctx: GenericActionCtx<DataModel>) {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) throw new Error("Not authenticated");
  const user = await ctx.runQuery(api.users.current, {});
  if (!user) throw new Error("User not found");
  return user;
}

async function generateCatName(base64Image: string): Promise<string> {
  const apiKey = requireEnv("GEMINI_API_KEY");
  const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{
        role: "user",
        parts: [
          { inlineData: { mimeType: "image/png", data: base64Image } },
          { text: NAME_PROMPT },
        ],
      }],
      generationConfig: { maxOutputTokens: 20 },
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${text}`);
  }

  const data = await response.json() as {
    candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    error?: { message?: string };
  };

  if (data.error?.message) throw new Error(`Gemini error: ${data.error.message}`);

  const raw = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
  // Strip any quotes or punctuation Gemini might add despite the prompt.
  const name = raw.replace(/['".,!?]/g, "").trim().split(/\s+/)[0] ?? "Cat";
  return name.slice(0, 12) || "Cat";
}

// ---------------------------------------------------------------------------
// Internal mutation — inserts the keepsake atomically, generates serial number
// ---------------------------------------------------------------------------

export const insertKeepsake = internalMutation({
  args: {
    ownerId: v.id("users"),
    name: v.string(),
    imageUrl: v.string(),
    cutoutUrl: v.string(),
    createdAt: v.number(),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("keepsakes")
      .withIndex("by_owner", (q) => q.eq("ownerId", args.ownerId))
      .collect();

    const serialNumber = `CAT-${String(existing.length + 1).padStart(4, "0")}`;

    const id = await ctx.db.insert("keepsakes", {
      ownerId: args.ownerId,
      name: args.name,
      rarity: "common",
      stats: { snack: 0, charm: 0 },
      abilities: [],
      imageUrl: args.imageUrl,
      cutoutUrl: args.cutoutUrl,
      colors: [],
      serialNumber,
      released: false,
      favorite: false,
      createdAt: args.createdAt,
    });

    return { id, serialNumber };
  },
});

// ---------------------------------------------------------------------------
// Public actions
// ---------------------------------------------------------------------------

/**
 * Request a presigned PUT URL for uploading a cutout PNG to R2.
 *
 * Cutouts are stored under the `cutouts/` prefix in the main R2 bucket,
 * distinguished from scan originals by path.
 */
export const requestCutoutUpload = action({
  args: {},
  handler: async (ctx): Promise<{ uploadUrl: string; r2Key: string }> => {
    const user = await requireUser(ctx);
    const r2Key = `cutouts/${user._id}/${Date.now()}.png`;
    const uploadUrl = await getSignedUploadUrl(r2Key, "image/png", 900);
    return { uploadUrl, r2Key };
  },
});

/**
 * Create a keepsake from an already-uploaded cutout PNG.
 *
 * Fetches the PNG from R2, sends it to Gemini to generate a name, then
 * inserts the keepsake record with a sequential serial number.
 */
export const create = action({
  args: { r2Key: v.string() },
  handler: async (ctx, args): Promise<{
    _id: string;
    name: string;
    cutoutUrl: string;
    serialNumber: string;
    createdAt: number;
  }> => {
    const user = await requireUser(ctx);

    const imageBytes = await getObjectBytes(args.r2Key);
    const base64Image = imageBytes.toString("base64");
    const name = await generateCatName(base64Image);

    const cutoutUrl = getPublicUrl(args.r2Key);
    const now = Date.now();

    const { id, serialNumber } = await ctx.runMutation(
      internal.keepsakes.insertKeepsake,
      { ownerId: user._id, name, imageUrl: cutoutUrl, cutoutUrl, createdAt: now }
    );

    return { _id: id, name, cutoutUrl, serialNumber, createdAt: now };
  },
});

// ---------------------------------------------------------------------------
// Query
// ---------------------------------------------------------------------------

/**
 * List all keepsakes for the authenticated user, newest first.
 */
export const list = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) return [];

    const user = await ctx.db
      .query("users")
      .withIndex("by_firebaseUid", (q) => q.eq("firebaseUid", identity.subject))
      .first();
    if (!user) return [];

    return await ctx.db
      .query("keepsakes")
      .withIndex("by_owner", (q) => q.eq("ownerId", user._id))
      .order("desc")
      .collect();
  },
});
