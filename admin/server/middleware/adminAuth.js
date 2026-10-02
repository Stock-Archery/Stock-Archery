import crypto from "crypto";

// Minimal signed-token auth for the admin web panel — no session store, no
// extra dependency. A token is `base64url(payload).hex(hmac)`; the payload
// carries an issued-at and expiry, so a leaked token stops working on its
// own without needing a server-side revocation list.
const SECRET = process.env.ADMIN_PANEL_SECRET;
const TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

function sign(payloadB64) {
  return crypto.createHmac("sha256", SECRET).update(payloadB64).digest("hex");
}

export function issueToken() {
  if (!SECRET) throw new Error("ADMIN_PANEL_SECRET is not set");
  const payload = { iat: Date.now(), exp: Date.now() + TOKEN_TTL_MS };
  const payloadB64 = Buffer.from(JSON.stringify(payload)).toString("base64url");
  return `${payloadB64}.${sign(payloadB64)}`;
}

export function verifyToken(token) {
  if (!SECRET || !token || typeof token !== "string" || !token.includes(".")) return false;

  const [payloadB64, signature] = token.split(".");
  const expectedHex = sign(payloadB64);

  const sigBuf = Buffer.from(signature || "", "hex");
  const expectedBuf = Buffer.from(expectedHex, "hex");
  if (sigBuf.length !== expectedBuf.length || !crypto.timingSafeEqual(sigBuf, expectedBuf)) {
    return false;
  }

  try {
    const payload = JSON.parse(Buffer.from(payloadB64, "base64url").toString("utf8"));
    return typeof payload.exp === "number" && payload.exp > Date.now();
  } catch {
    return false;
  }
}

export function requireAdminAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!verifyToken(token)) {
    return res.status(401).json({ status: "error", message: "Unauthorized" });
  }
  next();
}
