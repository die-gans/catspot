/**
 * Vision verdict shape for the server-side cat-scan verification pipeline.
 *
 * This mirrors the shared JSON schema in packages/shared/schema/vision_verdict.json
 * (to be generated into Dart/TS contracts later). It is authored here as the
 * source-of-truth TypeScript type until the codegen script is wired.
 */
export interface VisionVerdict {
  /** Whether the image contains a real, living cat (not a plush/screen/print). */
  isRealCat: boolean;
  /** Whether the photo appears to be a live capture (not a screenshot or photo-of-photo). */
  isLivePhoto: boolean;
  /** Detected breed, if identifiable. */
  breed?: string;
  /** Dominant colors observed in the cat. */
  colors: string[];
  /** Overall confidence score [0, 1]. */
  confidence: number;
}

/**
 * Verify a sighting image using the vision LLM.
 *
 * TODO(S1.7): implement with OpenAI gpt-4o-mini structured output and call from
 * the scanPipeline action.
 */
export async function verifySighting(imageUrl: string): Promise<VisionVerdict> {
  void imageUrl;
  throw new Error("verifySighting is not implemented yet");
}
