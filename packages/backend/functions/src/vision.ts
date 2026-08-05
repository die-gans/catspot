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
  type: "object" as const,
  properties: {
    is_real_cat: { type: "boolean" as const },
    is_live_photo: { type: "boolean" as const },
    confidence: { type: "number" as const, minimum: 0, maximum: 1 },
    reject_reason: { type: ["string", "null"] as ["string", "null"] },
  },
  required: ["is_real_cat", "is_live_photo", "confidence", "reject_reason"],
};

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing environment variable: ${key}`);
  }
  return value;
}

export async function callGemini(base64Image: string): Promise<Verdict> {
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
