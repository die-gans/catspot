import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

export interface R2Env {
  R2_ACCOUNT_ID: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_BUCKET_ORIGINALS: string;
  R2_BUCKET_CUTOUTS: string;
  R2_PUBLIC_URL: string;
}

function requireEnv<K extends keyof R2Env>(key: K): R2Env[K] {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing R2 environment variable: ${key}`);
  }
  return value;
}

/**
 * Create an S3 client configured for Cloudflare R2.
 *
 * R2 exposes an S3-compatible API endpoint per account.
 * Buckets are private; images are served only through signed URLs.
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
 * Generate a short-lived presigned PUT URL for an original image upload.
 *
 * TODO(S1.7): wire this into a scans action once scanPipeline is built.
 */
export async function getSignedUploadUrl(
  key: string,
  contentType: string = "image/jpeg"
): Promise<string> {
  const client = createR2Client();
  const bucket = requireEnv("R2_BUCKET_ORIGINALS");

  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    ContentType: contentType,
  });

  throw new Error(
    "getSignedUploadUrl is not implemented yet; signed URL generation stub only"
  );
  // eslint-disable-next-line no-unreachable
  return await getSignedUrl(client, command, { expiresIn: 300 });
}
