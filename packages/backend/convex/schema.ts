import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

/**
 * Convex schema v1 for Catspot (PRD §5.3).
 *
 * Tables are intentionally minimal where the PRD does not fully specify fields,
 * but all PRD tables and indexes are present.
 */
export default defineSchema({
  users: defineTable({
    firebaseUid: v.string(),
    email: v.optional(v.string()),
    displayName: v.optional(v.string()),
    avatar: v.optional(v.string()),
    xp: v.number(),
    level: v.number(),
    coins: v.number(),
    canCount: v.number(),
    canCap: v.number(),
    lastCanRegenAt: v.optional(v.number()), // Unix ms
    proTier: v.boolean(),
    streak: v.number(),
    settings: v.optional(
      v.object({
        pushNotifications: v.optional(v.boolean()),
        publicProfile: v.optional(v.boolean()),
      })
    ),
    createdAt: v.number(), // Unix ms
    deletedAt: v.optional(v.number()), // Unix ms, soft-delete
  })
    .index("by_firebaseUid", ["firebaseUid"])
    .index("by_email", ["email"]),

  keepsakes: defineTable({
    ownerId: v.id("users"),
    scanId: v.optional(v.id("scans")),
    name: v.string(), // generated name
    customName: v.optional(v.string()), // user override
    rarity: v.string(), // alley | garden | moonlit | velvet | golden
    type: v.optional(v.string()), // e.g. chonky, guard, copycat, finale
    stats: v.object({
      snack: v.number(),
      charm: v.number(),
    }),
    abilities: v.array(v.string()),
    imageUrl: v.string(),
    cutoutUrl: v.optional(v.string()),
    thumbUrl: v.optional(v.string()),
    embeddingId: v.optional(v.id("vectors")),
    breed: v.optional(v.string()),
    colors: v.array(v.string()),
    serialNumber: v.string(),
    released: v.boolean(),
    favorite: v.boolean(),
    createdAt: v.number(),
  })
    .index("by_owner", ["ownerId"])
    .index("by_owner_fav", ["ownerId", "favorite"])
    .index("by_rarity", ["rarity"])
    .index("by_serial", ["serialNumber"])
    .index("by_embedding", ["embeddingId"]),

  scans: defineTable({
    userId: v.id("users"),
    status: v.string(), // pending | verifying | accepted | rejected | duplicate
    imageUrl: v.string(),
    phash: v.optional(v.string()),
    verdict: v.optional(
      v.object({
        isRealCat: v.boolean(),
        isLivePhoto: v.boolean(),
        confidence: v.number(),
      })
    ),
    geo: v.optional(
      v.object({
        lat: v.number(),
        lng: v.number(),
        accuracy: v.optional(v.number()),
      })
    ),
    deviceMeta: v.optional(
      v.object({
        platform: v.string(),
        osVersion: v.optional(v.string()),
      })
    ),
    rejectionReason: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_user_status", ["userId", "status"])
    .index("by_phash", ["phash"]),

  sightings: defineTable({
    keepsakeId: v.id("keepsakes"),
    ownerId: v.id("users"),
    geohash: v.string(), // geohash-6, public coarse location
    coarseLat: v.number(),
    coarseLng: v.number(),
    rarity: v.string(),
    createdAt: v.number(),
  })
    .index("by_geohash", ["geohash"])
    .index("by_owner", ["ownerId"])
    .index("by_keepsake", ["keepsakeId"]),

  vectors: defineTable({
    keepsakeId: v.id("keepsakes"),
    embedding: v.array(v.float64()), // 512-d vector
    createdAt: v.number(),
  })
    .index("by_keepsake", ["keepsakeId"]),

  friendships: defineTable({
    aId: v.id("users"),
    bId: v.id("users"),
    status: v.string(), // pending | accepted | blocked
    createdAt: v.number(),
  })
    .index("by_a", ["aId"])
    .index("by_b", ["bId"])
    .index("by_pair", ["aId", "bId"]),

  reports: defineTable({
    reporterId: v.id("users"),
    targetType: v.string(), // pin | card | user
    targetId: v.string(),
    reason: v.string(),
    status: v.string(), // open | reviewed | dismissed
    createdAt: v.number(),
  })
    .index("by_target", ["targetType", "targetId"])
    .index("by_reporter", ["reporterId"]),

  economyLedger: defineTable({
    userId: v.id("users"),
    delta: v.number(), // negative for spend
    currency: v.string(), // coins | cans | xp
    reason: v.string(),
    refId: v.optional(v.string()), // scan, keepsake, ad, etc.
    idempotencyKey: v.string(),
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_idempotency", ["idempotencyKey"])
    .index("by_ref", ["refId"]),

  moderationQ: defineTable({
    scanId: v.id("scans"),
    priority: v.number(),
    status: v.string(), // pending | approved | rejected
    reviewerDecision: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_status", ["status", "priority"])
    .index("by_scan", ["scanId"]),

  rolls: defineTable({
    scanId: v.id("scans"),
    raritySeed: v.string(),
    rarityRoll: v.number(),
    createdAt: v.number(),
  })
    .index("by_scan", ["scanId"]),
});
