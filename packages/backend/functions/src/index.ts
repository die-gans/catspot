import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { user } from "firebase-functions/v1/auth";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getObjectBytes, getPublicUrl, uploadObjectBytes } from "./r2.js";
import { generateCatName } from "./vision.js";

initializeApp();

const db = getFirestore();

/**
 * Seed a user document when a new Firebase Auth account is created.
 *
 * Uses the v1 auth trigger because plain Firebase Auth onCreate is not
 * supported by the v2 API without GCIP identity blocking functions.
 */
export const seedUser = user().onCreate(async (user) => {
  const { uid, email, displayName, photoURL } = user;

  await db
    .collection("users")
    .doc(uid)
    .set({
      uid,
      email: email ?? null,
      displayName: displayName ?? null,
      photoURL: photoURL ?? null,
      xp: 0,
      coins: 0,
      createdAt: FieldValue.serverTimestamp(),
    });
});

// ---------------------------------------------------------------------------
// Keepsake functions
// ---------------------------------------------------------------------------

interface KeepsakeResponse {
  _id: string;
  name: string;
  cutoutUrl: string;
  serialNumber: string;
  createdAt: number;
}

interface CatchKeepsakeData {
  pngBase64: string;
}

/**
 * Record returned by `catchKeepsake`. Includes both the new canonical fields
 * (`r2Key`, `publicUrl`) and the legacy `cutoutUrl` alias so existing clients
 * keep working without a migration.
 */
interface CatchKeepsakeResponse {
  _id: string;
  uid: string;
  /** `null` while the async naming trigger has not run yet. */
  name: string | null;
  r2Key: string;
  publicUrl: string;
  cutoutUrl: string;
  serialNumber: string;
  rarity: string;
  createdAt: number;
}

/**
 * Placeholder name written by `catchKeepsake` before the async naming trigger
 * runs. We use `null` instead of a string placeholder so clients can tell the
 * name is still pending and show a spinner / fallback if they want.
 */
const PENDING_NAME = null;

async function computeNextSerialNumber(uid: string): Promise<string> {
  const existing = await db
    .collection("keepsakes")
    .where("uid", "==", uid)
    .count()
    .get();
  return `CAT-${String(existing.data().count + 1).padStart(4, "0")}`;
}

/**
 * Fast-path catch: decode the client's base64 PNG, upload it to R2, write a
 * Firestore keepsake doc with a placeholder name, and return the record
 * immediately. No Gemini call happens here — naming is handled asynchronously
 * by the `nameKeepsake` Firestore trigger.
 *
 * Auth required. Request shape: `{ pngBase64: string }`.
 */
export const catchKeepsake = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request): Promise<CatchKeepsakeResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Not authenticated");
    }

    const uid = request.auth.uid;
    const { pngBase64 } = request.data as CatchKeepsakeData;

    if (!pngBase64 || typeof pngBase64 !== "string") {
      throw new HttpsError("invalid-argument", "pngBase64 is required");
    }

    // Strip a data-URI prefix if the client sent one, then decode.
    const stripped = pngBase64.replace(/^data:image\/png;base64,/, "");
    const pngBytes = Buffer.from(stripped, "base64");
    if (pngBytes.length === 0) {
      throw new HttpsError("invalid-argument", "pngBase64 decoded to empty bytes");
    }

    const r2Key = `cutouts/${uid}/${Date.now()}.png`;
    await uploadObjectBytes(r2Key, pngBytes, "image/png");

    const publicUrl = getPublicUrl(r2Key);
    const serialNumber = await computeNextSerialNumber(uid);
    const createdAt = Date.now();

    const docRef = await db.collection("keepsakes").add({
      uid,
      name: PENDING_NAME,
      r2Key,
      publicUrl,
      cutoutUrl: publicUrl,
      serialNumber,
      rarity: "common",
      createdAt,
    });

    return {
      _id: docRef.id,
      uid,
      name: PENDING_NAME,
      r2Key,
      publicUrl,
      cutoutUrl: publicUrl,
      serialNumber,
      rarity: "common",
      createdAt,
    };
  }
);

/**
 * Firestore trigger that names a keepsake after it is created.
 *
 * Runs asynchronously: fetches the PNG from R2, calls Gemini to generate a
 * cat name, and updates the keepsake doc. Any failure is logged and swallowed;
 * the keepsake keeps its placeholder name (`null`) so the fast path never
 * blocks or fails.
 */
export const nameKeepsake = onDocumentCreated(
  { region: "us-central1", document: "keepsakes/{id}" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const r2Key = data?.r2Key as string | undefined;
    if (!r2Key) {
      console.warn(`nameKeepsake: keepsake ${snap.id} has no r2Key; skipping`);
      return;
    }

    const currentName = data?.name as string | null | undefined;
    if (currentName !== null && typeof currentName === "string" && currentName.length > 0) {
      console.log(`nameKeepsake: keepsake ${snap.id} already named "${currentName}"; skipping`);
      return;
    }

    try {
      const imageBytes = await getObjectBytes(r2Key);
      const name = await generateCatName(imageBytes.toString("base64"));
      await snap.ref.update({ name });
      console.log(`nameKeepsake: named keepsake ${snap.id} "${name}"`);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      console.error(`nameKeepsake: failed to name keepsake ${snap.id}: ${message}`);
      // Leave placeholder name; failure must not break anything.
    }
  }
);

/**
 * List all keepsakes for the authenticated user, newest first.
 */
export const listKeepsakes = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request): Promise<KeepsakeResponse[]> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Not authenticated");
    }

    const uid = request.auth.uid;
    const snapshot = await db
      .collection("keepsakes")
      .where("uid", "==", uid)
      .orderBy("createdAt", "desc")
      .get();

    return snapshot.docs.map((doc) => {
      const d = doc.data();
      return {
        _id: doc.id,
        name: (d["name"] as string | null) ?? "Cat",
        cutoutUrl: (d["publicUrl"] ?? d["cutoutUrl"]) as string,
        serialNumber: d["serialNumber"] as string,
        createdAt: d["createdAt"] as number,
      };
    });
  }
);
