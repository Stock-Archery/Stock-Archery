// Minimal ImageKit client using Node 18+ native fetch/FormData (no SDK).
// Needs IMAGEKIT_PRIVATE_KEY in this server's environment.

const UPLOAD_URL = "https://upload.imagekit.io/api/v1/files/upload";
const BULK_DELETE_URL = "https://api.imagekit.io/v1/files/batch/deleteByFileIds";

// Decoded size cap. ImageKit's own limit is higher; this just stops absurd
// payloads before they're forwarded.
export const MAX_IMAGE_BYTES = 15 * 1024 * 1024;

export function isConfigured() {
  return !!process.env.IMAGEKIT_PRIVATE_KEY;
}

// ImageKit uses HTTP Basic auth: private key as the username, empty password.
function authHeader() {
  return "Basic " + Buffer.from(`${process.env.IMAGEKIT_PRIVATE_KEY}:`).toString("base64");
}

// Accepts raw base64 or a data URI and returns raw base64.
export function normalizeBase64(input) {
  return String(input).replace(/^data:[^;]+;base64,/, "").trim();
}

export function decodedSize(base64) {
  const padding = base64.endsWith("==") ? 2 : base64.endsWith("=") ? 1 : 0;
  return Math.floor((base64.length * 3) / 4) - padding;
}

// Sniffs the real file type from the first bytes. Returns 'jpg' | 'png' |
// 'webp', or null if it isn't an image we accept.
export function detectImageType(base64) {
  const head = Buffer.from(base64.slice(0, 32), "base64");
  if (head[0] === 0xff && head[1] === 0xd8 && head[2] === 0xff) return "jpg";
  if (head.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return "png";
  if (head.subarray(0, 4).toString("ascii") === "RIFF" && head.subarray(8, 12).toString("ascii") === "WEBP") return "webp";
  return null;
}

// Uploads a raw base64 image. Returns { url, fileId }. Throws on failure,
// with err.status set to ImageKit's HTTP status when there is one.
export async function uploadImage(base64, { folder, fileNamePrefix, type }) {
  const form = new FormData();
  form.append("file", base64);
  form.append("fileName", `${fileNamePrefix}_${Date.now()}.${type}`);
  form.append("folder", folder);
  form.append("useUniqueFileName", "true");

  const res = await fetch(UPLOAD_URL, {
    method: "POST",
    headers: { Authorization: authHeader() },
    body: form,
    signal: AbortSignal.timeout(30000),
  });

  if (!res.ok) {
    const err = new Error(`ImageKit upload failed: ${res.status} ${(await res.text()).slice(0, 200)}`);
    err.status = res.status;
    throw err;
  }

  const data = await res.json();
  return { url: data.url, fileId: data.fileId };
}

// Best-effort cleanup. Never throws: a failed delete must not fail a request.
export async function deleteFiles(fileIds) {
  if (!isConfigured() || !fileIds || fileIds.length === 0) return;

  for (let i = 0; i < fileIds.length; i += 100) {
    const chunk = fileIds.slice(i, i + 100);
    try {
      const res = await fetch(BULK_DELETE_URL, {
        method: "POST",
        headers: { Authorization: authHeader(), "Content-Type": "application/json" },
        body: JSON.stringify({ fileIds: chunk }),
        signal: AbortSignal.timeout(20000),
      });
      if (!res.ok) {
        console.error(`ImageKit bulk delete failed: ${res.status} ${await res.text()}`);
      }
    } catch (err) {
      console.error("ImageKit bulk delete error:", err.message);
    }
  }
}
