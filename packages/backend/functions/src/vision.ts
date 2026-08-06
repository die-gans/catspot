/**
 * Generate a short, charming cat name from a PNG image.
 *
 * Sends the image to Gemini and returns a single capitalized word (max 12
 * chars). Falls back to "Cat" if the model returns something unusable.
 */
export async function generateCatName(base64Image: string): Promise<string> {
  const GEMINI_MODEL = "gemini-3.1-flash-lite";
  const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;
  const apiKey = process.env["GEMINI_API_KEY"];
  if (!apiKey) throw new Error("Missing GEMINI_API_KEY");

  const NAME_PROMPT = `You are naming a cat in a real-world cat-spotting mobile game.
Look at this PNG image of a cat (background already removed).
Give this specific cat a single charming name that suits its appearance, color, and vibe.
Output ONLY the name — one word, max 12 characters, capitalized. No quotes, no punctuation, no explanation.
Examples: Mochi, Shadow, Biscuit, Marmalade, Bean, Whisker, Patches, Goose, Pretzel`;

  const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
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
