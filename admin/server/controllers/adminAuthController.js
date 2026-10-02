import crypto from "crypto";
import { issueToken } from "../middleware/adminAuth.js";

// Naive in-memory brute-force guard: fine for a single pm2 instance
// protecting one shared admin password. Resets on restart, which is an
// acceptable trade-off for not needing a datastore just for this.
const attempts = new Map(); // ip -> { count, lockedUntil }
const MAX_ATTEMPTS = 5;
const LOCKOUT_MS = 15 * 60 * 1000;

function timingSafeEqualStr(a, b) {
  const aBuf = Buffer.from(String(a));
  const bBuf = Buffer.from(String(b));
  if (aBuf.length !== bBuf.length) {
    // Compare against itself so a length mismatch doesn't short-circuit
    // (and leak length via timing) before reaching timingSafeEqual.
    crypto.timingSafeEqual(aBuf, aBuf);
    return false;
  }
  return crypto.timingSafeEqual(aBuf, bBuf);
}

export const login = (req, res) => {
  const ip = req.ip;
  const record = attempts.get(ip);

  if (record?.lockedUntil && record.lockedUntil > Date.now()) {
    const waitMin = Math.ceil((record.lockedUntil - Date.now()) / 60000);
    console.log(`[log] POST /admin/login — 429: ${ip} locked out (${waitMin}m left)`);
    return res.status(429).json({ status: "error", message: `Too many attempts. Try again in ${waitMin} min.` });
  }

  const { password } = req.body || {};
  const expected = process.env.ADMIN_PANEL_PASSWORD;

  if (!expected || expected === "CHANGE_ME") {
    console.error("[log] POST /admin/login — 500: ADMIN_PANEL_PASSWORD is not configured");
    return res.status(500).json({ status: "error", message: "Admin panel is not configured yet" });
  }

  if (!password || !timingSafeEqualStr(password, expected)) {
    const next = { count: (record?.count || 0) + 1, lockedUntil: null };
    if (next.count >= MAX_ATTEMPTS) next.lockedUntil = Date.now() + LOCKOUT_MS;
    attempts.set(ip, next);
    console.log(`[log] POST /admin/login — 401: wrong password from ${ip} (attempt ${next.count})`);
    return res.status(401).json({ status: "error", message: "Incorrect password" });
  }

  attempts.delete(ip);
  const token = issueToken();
  console.log(`[log] POST /admin/login — 200: ok from ${ip}`);
  res.json({ status: "success", token });
};
