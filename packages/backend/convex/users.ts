import { v } from "convex/values";
import { mutationGeneric, queryGeneric } from "convex/server";
import type { GenericMutationCtx, GenericQueryCtx } from "convex/server";
import type { DataModel, Doc } from "./_generated/dataModel.js";

/**
 * Return the currently authenticated user document, or null if not signed in.
 */
export const current = queryGeneric({
  args: {},
  handler: async (
    ctx: GenericQueryCtx<DataModel>,
    _args: Record<string, unknown>
  ): Promise<Doc<"users"> | null> => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      return null;
    }
    return await ctx.db
      .query("users")
      .withIndex("by_firebaseUid", (q) => q.eq("firebaseUid", identity.subject))
      .unique();
  },
});

/**
 * Create or update the users row from the Firebase Auth identity claims.
 *
 * Called by the client after a Firebase sign-in; the first call creates the row,
 * subsequent calls update the profile fields. The identity `subject` is the
 * Firebase UID; email, name, and picture are read from the Firebase ID token.
 */
export const upsertFromFirebase = mutationGeneric({
  args: {
    // Optional overrides passed by the client; identity claims are authoritative.
    displayName: v.optional(v.string()),
    avatar: v.optional(v.string()),
  },
  handler: async (
    ctx: GenericMutationCtx<DataModel>,
    args: { displayName?: string; avatar?: string }
  ): Promise<Doc<"users">["_id"]> => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }

    const firebaseUid = identity.subject;
    const existing = await ctx.db
      .query("users")
      .withIndex("by_firebaseUid", (q) => q.eq("firebaseUid", firebaseUid))
      .unique();

    const now = Date.now();
    const displayName = args.displayName ?? identity.name ?? "Catspotter";
    const avatar = args.avatar ?? identity.pictureUrl;

    if (existing) {
      await ctx.db.patch(existing._id, {
        displayName,
        avatar,
        email: identity.email,
      });
      return existing._id;
    }

    return await ctx.db.insert("users", {
      firebaseUid,
      email: identity.email,
      displayName,
      avatar,
      xp: 0,
      level: 1,
      coins: 0,
      canCount: 10,
      canCap: 10,
      lastCanRegenAt: now,
      proTier: false,
      streak: 0,
      settings: { pushNotifications: true, publicProfile: false },
      createdAt: now,
    });
  },
});
