import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { getObjectBytes, getSignedUploadUrl } from "./r2.js";
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
