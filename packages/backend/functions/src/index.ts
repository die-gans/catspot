import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { user } from "firebase-functions/v1/auth";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getObjectBytes, getPublicUrl, getSignedUploadUrl, uploadObjectBytes } from "./r2.js";
import { callGemini, generateCatName, type Verdict } from "./vision.js";

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

/**
 * Request a new scan upload.
 *
 * Authenticated users only. Creates a Firestore scan document in
 * `awaiting_upload` state, then returns the scan id and a presigned R2 PUT URL
 * for the original JPEG. The client uploads directly to R2; the key format is
 * `scans/{uid}/{scanId}.jpg`.
 */
export const requestScan = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
  },
  async (request): Promise<{ scanId: string; uploadUrl: string }> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Not authenticated");
    }

    const uid = request.auth.uid;
    const scanRef = db.collection("scans").doc();
    const scanId = scanRef.id;
    const r2Key = `scans/${uid}/${scanId}.jpg`;

    const uploadUrl = await getSignedUploadUrl(r2Key, "image/jpeg", 900);

    await scanRef.set({
      uid,
      status: "awaiting_upload",
      r2Key,
      createdAt: FieldValue.serverTimestamp(),
    });

    return { scanId, uploadUrl };
  }
);

interface VerifyScanData {
  scanId: string;
}

/**
 * Verify an uploaded scan with Gemini.
 *
 * Authenticated, owner-only. Fetches the JPEG from R2, base64-encodes it, calls
 * Gemini 2.5 Flash with the verdict prompt, and updates the scan document with
 * the structured verdict. Rejected images still record a verdict; errors move
 * the scan to `error` status and preserve the message.
 */
export const verifyScan = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
  },
  async (request): Promise<{ verdict: Verdict }> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Not authenticated");
    }

    const uid = request.auth.uid;
    const { scanId } = request.data as VerifyScanData;

    if (!scanId || typeof scanId !== "string") {
      throw new HttpsError("invalid-argument", "scanId is required");
    }

    const scanRef = db.collection("scans").doc(scanId);
    const scanDoc = await scanRef.get();

    if (!scanDoc.exists) {
      throw new HttpsError("not-found", "Scan not found");
    }

    const scan = scanDoc.data() as { uid: string; r2Key?: string };
    if (scan.uid !== uid) {
      throw new HttpsError("permission-denied", "Forbidden");
    }
    if (!scan.r2Key) {
      throw new HttpsError("failed-precondition", "Scan has no uploaded image");
    }

    try {
      const imageBytes = await getObjectBytes(scan.r2Key);
      const base64Image = imageBytes.toString("base64");
      const verdict = await callGemini(base64Image);
      const status = verdict.is_real_cat && verdict.is_live_photo
        ? "verified"
        : "rejected";

      await scanRef.update({
        status,
        verdict,
        r2Key: scan.r2Key,
        verifiedAt: FieldValue.serverTimestamp(),
      });

      return { verdict };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      await scanRef.update({
        status: "error",
        errorMessage: message,
      });
      throw new HttpsError("internal", message);
    }
  }
);

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

    // Skip if the doc was written with an already-resolved name (e.g. by the
    // legacy createKeepsake path).
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
 * Request a presigned PUT URL for uploading a cat cutout PNG to R2.
 *
 * @deprecated Mobile is switching to `catchKeepsake`; this 2-step upload flow
 * is kept temporarily as a shim for any in-flight clients.
 */
export const requestCutoutUpload = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request): Promise<{ uploadUrl: string; r2Key: string }> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Not authenticated");
    }

    const uid = request.auth.uid;
    const r2Key = `cutouts/${uid}/${Date.now()}.png`;
    const uploadUrl = await getSignedUploadUrl(r2Key, "image/png", 900);
    return { uploadUrl, r2Key };
  }
);

interface CreateKeepsakeData {
  r2Key: string;
}

/**
 * Create a keepsake from an already-uploaded cutout PNG.
 *
 * @deprecated Mobile is switching to `catchKeepsake`; this function is kept
 * temporarily as a shim for any in-flight clients. It still performs inline
 * Gemini naming (slower) and does not populate the canonical `r2Key` field.
 */
export const createKeepsake = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request): Promise<KeepsakeResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Not authenticated");
    }

    const uid = request.auth.uid;
    const { r2Key } = request.data as CreateKeepsakeData;

    if (!r2Key || typeof r2Key !== "string") {
      throw new HttpsError("invalid-argument", "r2Key is required");
    }

    const serialNumber = await computeNextSerialNumber(uid);
    const imageBytes = await getObjectBytes(r2Key);
    const name = await generateCatName(imageBytes.toString("base64"));

    const cutoutUrl = getPublicUrl(r2Key);
    const createdAt = Date.now();

    const docRef = await db.collection("keepsakes").add({
      uid,
      name,
      cutoutUrl,
      serialNumber,
      rarity: "common",
      createdAt,
    });

    return { _id: docRef.id, name, cutoutUrl, serialNumber, createdAt };
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
