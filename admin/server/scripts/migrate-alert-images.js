// One-off migration: moves alert images that were stored inline as base64 in
// MongoDB to ImageKit, then replaces the base64 with the ImageKit link.
//
//   node scripts/migrate-alert-images.js                 dry run (default): reads only
//   node scripts/migrate-alert-images.js --apply         actually migrate
//   node scripts/migrate-alert-images.js --apply --limit=5
//
// Safe to re-run: posts that already have an imageUrl are skipped. A post's
// base64 is only removed AFTER its ImageKit copy has been fetched back and
// confirmed to load, so a failure never loses an image.

import dotenv from "dotenv";
import mongoose from "mongoose";
import { pathToFileURL } from "url";
import AlertPost from "../models/AlertPost.js";
import {
  isConfigured,
  normalizeBase64,
  decodedSize,
  detectImageType,
  uploadImage,
  deleteFiles,
} from "../services/imagekit.js";

export async function migrate({ apply = false, limit = 0, log = console.log } = {}) {
  const summary = { found: 0, migrated: 0, skipped: 0, failed: 0, bytes: 0 };

  if (apply && !isConfigured()) {
    throw new Error("IMAGEKIT_PRIVATE_KEY is not set — cannot migrate");
  }

  const filter = {
    imageBase64: { $type: "string", $ne: "" },
    $or: [{ imageUrl: null }, { imageUrl: { $exists: false } }],
  };
  let query = AlertPost.find(filter).sort({ createdAt: 1 });
  if (limit > 0) query = query.limit(limit);

  for await (const doc of query.cursor()) {
    summary.found++;
    const base64 = normalizeBase64(doc.imageBase64);
    const type = detectImageType(base64);
    const size = decodedSize(base64);
    summary.bytes += size;

    if (!type) {
      log(`SKIP  ${doc._id}: not a JPEG/PNG/WebP image`);
      summary.skipped++;
      continue;
    }
    if (!apply) {
      log(`WOULD MIGRATE ${doc._id} [${doc.category}] ${type} ${(size / 1024).toFixed(0)} KB`);
      continue;
    }

    let uploaded = null;
    try {
      uploaded = await uploadImage(base64, {
        folder: `/stock-archery/alerts/${doc.category.toLowerCase()}`,
        fileNamePrefix: `alert_${doc.category.toLowerCase()}`,
        type,
      });

      // Only trust the copy once it can actually be fetched back.
      const check = await fetch(uploaded.url, { method: "HEAD" });
      if (!check.ok) throw new Error(`uploaded image not reachable (HTTP ${check.status})`);

      await AlertPost.updateOne(
        { _id: doc._id },
        { $set: { imageUrl: uploaded.url, imageFileId: uploaded.fileId }, $unset: { imageBase64: 1 } },
        { timestamps: false } // keep the original createdAt
      );
      log(`OK    ${doc._id} -> ${uploaded.url}`);
      summary.migrated++;
    } catch (err) {
      log(`FAIL  ${doc._id}: ${err.message}`);
      summary.failed++;
      if (uploaded) await deleteFiles([uploaded.fileId]);
    }
  }

  return summary;
}

// CLI entry point (skipped when this file is imported, e.g. by tests).
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  dotenv.config();
  const apply = process.argv.includes("--apply");
  const limitArg = process.argv.find((a) => a.startsWith("--limit="));
  const limit = limitArg ? parseInt(limitArg.split("=")[1], 10) || 0 : 0;

  console.log(apply ? "MODE: APPLY (will modify data)" : "MODE: dry run (no changes)");
  await mongoose.connect(process.env.mongoUri);
  try {
    const s = await migrate({ apply, limit });
    console.log(
      `\nfound ${s.found} | migrated ${s.migrated} | skipped ${s.skipped} | failed ${s.failed} | ` +
        `${(s.bytes / (1024 * 1024)).toFixed(1)} MB of base64`
    );
    if (!apply && s.found > 0) console.log("Re-run with --apply to migrate.");
  } finally {
    await mongoose.disconnect();
  }
}
