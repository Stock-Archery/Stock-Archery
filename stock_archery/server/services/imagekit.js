// Minimal ImageKit client using Node 18+ native fetch/FormData (no SDK).
// Needs IMAGEKIT_PRIVATE_KEY. Optional: IMAGEKIT_FOLDER.

const UPLOAD_URL = 'https://upload.imagekit.io/api/v1/files/upload';
const BULK_DELETE_URL = 'https://api.imagekit.io/v1/files/batch/deleteByFileIds';

function isConfigured() {
  return !!process.env.IMAGEKIT_PRIVATE_KEY;
}

// ImageKit uses HTTP Basic auth: private key as the username, empty password.
function authHeader() {
  return 'Basic ' + Buffer.from(`${process.env.IMAGEKIT_PRIVATE_KEY}:`).toString('base64');
}

// Uploads a raw base64 image. Returns { url, fileId }, or null if ImageKit
// isn't configured. Throws if the upload itself fails.
async function uploadChartImage(base64, uid) {
  if (!isConfigured()) {
    console.warn('⚠️ IMAGEKIT_PRIVATE_KEY not set — chart image will not be stored.');
    return null;
  }

  const form = new FormData();
  form.append('file', base64);
  form.append('fileName', `chart_${uid}_${Date.now()}.jpg`);
  form.append('folder', process.env.IMAGEKIT_FOLDER || '/stock-archery/chart-analysis');
  form.append('useUniqueFileName', 'true');

  const res = await fetch(UPLOAD_URL, {
    method: 'POST',
    headers: { Authorization: authHeader() },
    body: form,
    signal: AbortSignal.timeout(20000),
  });

  if (!res.ok) {
    throw new Error(`ImageKit upload failed: ${res.status} ${await res.text()}`);
  }

  const data = await res.json();
  return { url: data.url, fileId: data.fileId };
}

// Best-effort cleanup. Never throws: a failed delete must not fail the request.
async function deleteFiles(fileIds) {
  if (!isConfigured() || !fileIds || fileIds.length === 0) return;

  for (let i = 0; i < fileIds.length; i += 100) {
    const chunk = fileIds.slice(i, i + 100);
    try {
      const res = await fetch(BULK_DELETE_URL, {
        method: 'POST',
        headers: { Authorization: authHeader(), 'Content-Type': 'application/json' },
        body: JSON.stringify({ fileIds: chunk }),
        signal: AbortSignal.timeout(20000),
      });
      if (!res.ok) {
        console.error(`ImageKit bulk delete failed: ${res.status} ${await res.text()}`);
      }
    } catch (err) {
      console.error('ImageKit bulk delete error:', err.message);
    }
  }
}

module.exports = { isConfigured, uploadChartImage, deleteFiles };
