import { v } from "convex/values";
import { action, internalMutation } from "./_generated/server.js";
import type { GenericActionCtx } from "convex/server";
import type { DataModel, Doc } from "./_generated/dataModel.js";
import { api, internal } from "./_generated/api.js";
import { getObjectBytes, getSignedUploadUrl } from "./lib/r2.js";

/**
 * Structured verdict returned by the Gemini vision check.
 *
 * Shape is contractually fixed; the Flutter scan screen depends on these
 * exact snake_case keys.
 */
export interface Verdict {
  /** True when the image contains an actual cat (not a dog, toy, drawing, etc.). */
  is_real_cat: boolean;
  /** True when the photo is a live camera capture (not a screen, print, plush, etc.). */
  is_live_photo: boolean;
  /** Overall confidence in the verdict, in [0, 1]. */
  confidence: number;
  /** Human-readable reason when the scan is rejected; null otherwise. */
  reject_reason: string | null;
}

const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const VERDICT_PROMPT = `You are the image verifier for a real-world cat spotting game.

Analyze the uploaded image and decide whether it shows a real, living cat that was photographed directly by a camera. Reject:
- photos of screens, monitors, prints, paintings, or drawings
- plush toys, statues, costumes, or other non-living representations
- non-cat animals or objects

Return a JSON object with these exact fields:
- is_real_cat (boolean)
- is_live_photo (boolean)
- confidence (number between 0 and 1)
- reject_reason (string explanation, or null if approved)`;

const verdictResponseSchema = {
  type: "object",
  properties: {
    is_real_cat: { type: "boolean" },
    is_live_photo: { type: "boolean" },
    confidence: { type: "number", minimum: 0, maximum: 1 },
    reject_reason: { type: ["string", "null"] as ["string", "null"] },
  },
  required: ["is_real_cat", "is_live_photo", "confidence", "reject_reason"],
};

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing Convex environment variable: ${key}`);
  }
  return value;
}

/**
 * Require an authenticated Firebase user, matching the pattern used in users.ts.
 *
 * Convex validates the Firebase ID token; `identity.subject` is the Firebase UID.
 * We then look up the corresponding Catspot user row via the existing public query.
 */
async function requireUser(
  ctx: GenericActionCtx<DataModel>
): Promise<Doc<"users">> {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) {
    throw new Error("Not authenticated");
  }

  const user = await ctx.runQuery(api.users.current, {});
  if (!user) {
    throw new Error("User not found");
  }
  return user;
}

export const createScan = internalMutation({
  args: {
    userId: v.id("users"),
    status: v.string(),
    r2Key: v.optional(v.string()),
    createdAt: v.number(),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("scans", {
      userId: args.userId,
      status: args.status as Doc<"scans">["status"],
      r2Key: args.r2Key,
      createdAt: args.createdAt,
    });
  },
});

export const updateScan = internalMutation({
  args: {
    scanId: v.id("scans"),
    status: v.optional(v.string()),
    r2Key: v.optional(v.string()),
    verdict: v.optional(v.any()),
    verifiedAt: v.optional(v.number()),
    errorMessage: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const patch: Partial<Doc<"scans">> = {};
    if (args.status !== undefined) {
      patch.status = args.status as Doc<"scans">["status"];
    }
    if (args.r2Key !== undefined) {
      patch.r2Key = args.r2Key;
    }
    if (args.verdict !== undefined) {
      patch.verdict = args.verdict as Doc<"scans">["verdict"];
    }
    if (args.verifiedAt !== undefined) {
      patch.verifiedAt = args.verifiedAt;
    }
    if (args.errorMessage !== undefined) {
      patch.errorMessage = args.errorMessage;
    }
    await ctx.db.patch(args.scanId, patch);
  },
});

export const getScanById = internalMutation({
  args: { scanId: v.id("scans") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.scanId);
  },
});

/**
 * Request a new scan upload.
 *
 * Authenticated users only. Creates a scan document in `awaiting_upload` state,
 * then returns the scan id and a presigned R2 PUT URL for the original JPEG.
 * The client uploads directly to R2; the key format is `scans/{userId}/{scanId}.jpg`.
 */
export const requestScan = action({
  args: {},
  handler: async (
    ctx: GenericActionCtx<DataModel>
  ): Promise<{ scanId: string; uploadUrl: string }> => {
    const user = await requireUser(ctx);
    const now = Date.now();

    const scanId = await ctx.runMutation(internal.scans.createScan, {
      userId: user._id,
      status: "awaiting_upload",
      createdAt: now,
    });

    const r2Key = `scans/${user._id}/${scanId}.jpg`;
    const [uploadUrl] = await Promise.all([
      getSignedUploadUrl(r2Key, "image/jpeg", 900),
      ctx.runMutation(internal.scans.updateScan, { scanId, r2Key }),
    ]);

    return { scanId, uploadUrl };
  },
});

/**
 * Verify an uploaded scan with Gemini.
 *
 * Authenticated, owner-only. Fetches the JPEG from R2, base64-encodes it, calls
 * Gemini 2.5 Flash with the verdict prompt, and updates the scan document with
 * the structured verdict. Rejected images still record a verdict; errors move
 * the scan to `error` status and preserve the message.
 */
export const verify = action({
  args: { scanId: v.id("scans") },
  handler: async (
    ctx: GenericActionCtx<DataModel>,
    args
  ): Promise<{ verdict: Verdict }> => {
    const user = await requireUser(ctx);
    const scan = await ctx.runMutation(internal.scans.getScanById, { scanId: args.scanId });
    if (!scan) {
      throw new Error("Scan not found");
    }
    if (scan.userId !== user._id) {
      throw new Error("Forbidden");
    }
    if (!scan.r2Key) {
      throw new Error("Scan has no uploaded image");
    }

    try {
      const imageBytes = await getObjectBytes(scan.r2Key);
      const base64Image = imageBytes.toString("base64");
      const verdict = await callGemini(base64Image);
      const now = Date.now();
      const status = verdict.is_real_cat && verdict.is_live_photo
        ? "verified"
        : "rejected";

      await ctx.runMutation(internal.scans.updateScan, {
        scanId: args.scanId,
        status,
        verdict,
        verifiedAt: now,
      });

      return { verdict };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      await ctx.runMutation(internal.scans.updateScan, {
        scanId: args.scanId,
        status: "error",
        errorMessage: message,
      });
      throw new Error(message);
    }
  },
});

async function callGemini(base64Image: string): Promise<Verdict> {
  const apiKey = requireEnv("GEMINI_API_KEY");

  const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          role: "user",
          parts: [
            {
              inlineData: {
                mimeType: "image/jpeg",
                data: base64Image,
              },
            },
            { text: VERDICT_PROMPT },
          ],
        },
      ],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: verdictResponseSchema,
      },
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${text}`);
  }

  const data = (await response.json()) as {
    candidates?: Array<{
      content?: {
        parts?: Array<{ text?: string }>;
      };
      finishReason?: string;
    }>;
    error?: { message?: string };
  };

  if (data.error?.message) {
    throw new Error(`Gemini API error: ${data.error.message}`);
  }

  const candidate = data.candidates?.[0];
  if (!candidate) {
    throw new Error("Gemini returned no candidates");
  }
  if (candidate.finishReason && candidate.finishReason !== "STOP") {
    throw new Error(`Gemini finish reason: ${candidate.finishReason}`);
  }

  const text = candidate.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error("Gemini returned empty content");
  }

  const parsed = JSON.parse(text) as Verdict;
  if (
    typeof parsed.is_real_cat !== "boolean" ||
    typeof parsed.is_live_photo !== "boolean" ||
    typeof parsed.confidence !== "number" ||
    !(parsed.reject_reason === null || typeof parsed.reject_reason === "string")
  ) {
    throw new Error(`Unexpected Gemini verdict shape: ${text}`);
  }

  return parsed;
}
