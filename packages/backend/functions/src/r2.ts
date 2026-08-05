import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing environment variable: ${key}`);
  }
  return value;
}

/**
 * Create an S3 client configured for Cloudflare R2.
 *
 * R2 exposes an S3-compatible API endpoint per account. Buckets are private;
 * images are served only through signed URLs.
 */
export function createR2Client(): S3Client {
  const accountId = requireEnv("R2_ACCOUNT_ID");
  return new S3Client({
    region: "auto",
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: requireEnv("R2_ACCESS_KEY_ID"),
      secretAccessKey: requireEnv("R2_SECRET_ACCESS_KEY"),
    },
  });
}

/**
 * Generate a short-lived presigned PUT URL for an image upload.
 *
 * The client uploads the original JPEG directly to R2 using this URL.
 */
export async function getSignedUploadUrl(
  key: string,
  contentType: string = "image/jpeg",
  expiresIn: number = 900
): Promise<string> {
  const client = createR2Client();
  const bucket = requireEnv("R2_BUCKET");

  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    ContentType: contentType,
  });

  return getSignedUrl(client, command, { expiresIn });
}

/**
 * Fetch an object's bytes from R2.
 *
 * Used by server-side functions (e.g. Gemini verification) that need the
 * uploaded image body. Returns a Node.js Buffer.
 */
export async function getObjectBytes(key: string): Promise<Buffer> {
  const client = createR2Client();
  const bucket = requireEnv("R2_BUCKET");

  const response = await client.send(
    new GetObjectCommand({ Bucket: bucket, Key: key })
  );

  if (!response.Body) {
    throw new Error(`R2 object not found or empty: ${key}`);
  }

  const chunks: Uint8Array[] = [];
  for await (const chunk of response.Body as AsyncIterable<Uint8Array>) {
    chunks.push(chunk);
  }

  return Buffer.concat(chunks);
}
