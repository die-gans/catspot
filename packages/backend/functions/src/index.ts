import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { getObjectBytes, getPublicUrl, getSignedUploadUrl } from "./r2.js";
import { callGemini, type Verdict } from "./vision.js";

initializeApp();

const db = getFirestore();

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

const GEMINI_MODEL_NAME = "gemini-2.5-flash";
const GEMINI_NAME_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL_NAME}:generateContent`;

const NAME_PROMPT = `You are naming a cat in a real-world cat-spotting mobile game.
Look at this PNG image of a cat (background already removed).
Give this specific cat a single charming name that suits its appearance, color, and vibe.
Output ONLY the name — one word, max 12 characters, capitalized. No quotes, no punctuation, no explanation.
Examples: Mochi, Shadow, Biscuit, Marmalade, Bean, Whisker, Patches, Goose, Pretzel`;

async function generateCatName(base64Image: string): Promise<string> {
  const apiKey = process.env["GEMINI_API_KEY"];
  if (!apiKey) throw new Error("Missing GEMINI_API_KEY");

  const response = await fetch(`${GEMINI_NAME_URL}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [
        { inlineData: { mimeType: "image/png", data: base64Image } },
        { text: NAME_PROMPT },
      ]}],
      generationConfig: { maxOutputTokens: 20 },
    }),
  });

  if (!response.ok) {
    throw new Error(`Gemini error ${response.status}: ${await response.text()}`);
  }

  const data = await response.json() as {
    candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
  };
  const raw = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
  const name = raw.replace(/['".,!?]/g, "").trim().split(/\s+/)[0] ?? "Cat";
  return name.slice(0, 12) || "Cat";
}

/**
 * Request a presigned PUT URL for uploading a cat cutout PNG to R2.
 *
 * Returns `{ uploadUrl, r2Key }`. The client PUTs the PNG bytes directly to
 * `uploadUrl`; the key is passed back to `createKeepsake` afterwards.
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

interface KeepsakeResponse {
  _id: string;
  name: string;
  cutoutUrl: string;
  serialNumber: string;
  createdAt: number;
}

/**
 * Create a keepsake from an already-uploaded cutout PNG.
 *
 * Fetches the PNG from R2, sends it to Gemini 2.5 Flash to generate a cat
 * name, writes the keepsake document to Firestore, and returns the record.
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

    // Count existing keepsakes to assign a serial number.
    const existing = await db
      .collection("keepsakes")
      .where("uid", "==", uid)
      .count()
      .get();
    const serialNumber = `CAT-${String(existing.data().count + 1).padStart(4, "0")}`;

    // Fetch PNG and generate a name via Gemini.
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
        name: d["name"] as string,
        cutoutUrl: d["cutoutUrl"] as string,
        serialNumber: d["serialNumber"] as string,
        createdAt: d["createdAt"] as number,
      };
    });
  }
);
