import ExcelJS from "exceljs";
import User from "../models/User.js";

const SORTABLE_FIELDS = new Set(["createdAt", "name", "premiumExpiresAt", "textChatCount", "email"]);

// Shared by listUsers and exportUsers so "export" always matches what the
// admin is currently looking at on screen.
function buildFilter(query) {
  const { search, state, occupation, gender, tradingExperience, premium, from, to } = query;
  const filter = {};

  if (search && search.trim()) {
    const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const re = new RegExp(escaped, "i");
    filter.$or = [{ name: re }, { email: re }, { phoneNumber: re }];
  }
  if (state && state !== "all") filter.state = state;
  if (occupation && occupation !== "all") filter.occupation = occupation;
  if (gender && gender !== "all") filter.gender = gender;
  if (tradingExperience && tradingExperience !== "all") filter.tradingExperience = tradingExperience;
  if (premium === "premium") filter.isPremium = true;
  if (premium === "free") filter.isPremium = { $ne: true };

  if (from || to) {
    filter.createdAt = {};
    if (from) filter.createdAt.$gte = new Date(from);
    if (to) {
      const end = new Date(to);
      end.setHours(23, 59, 59, 999); // `to` is inclusive of the whole day
      filter.createdAt.$lte = end;
    }
  }

  return filter;
}

function buildSort(query) {
  const field = SORTABLE_FIELDS.has(query.sortBy) ? query.sortBy : "createdAt";
  const order = query.order === "asc" ? 1 : -1;
  return { [field]: order };
}

export const listUsers = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(200, Math.max(1, parseInt(req.query.limit, 10) || 25));
    const filter = buildFilter(req.query);
    const sort = buildSort(req.query);

    const [users, total] = await Promise.all([
      User.find(filter).sort(sort).skip((page - 1) * limit).limit(limit).select("-__v").lean(),
      User.countDocuments(filter),
    ]);

    res.json({
      status: "success",
      page,
      limit,
      total,
      totalPages: Math.max(1, Math.ceil(total / limit)),
      users,
    });
  } catch (err) {
    console.error("[log] GET /admin/users — 500:", err.message);
    res.status(500).json({ status: "error", message: "Failed to fetch users" });
  }
};

export const getMeta = async (req, res) => {
  try {
    // `state` is free text (not a fixed enum), so the dropdown needs the
    // actual distinct values currently in the DB rather than a hardcoded list.
    const states = await User.distinct("state", { state: { $nin: [null, ""] } });
    res.json({
      status: "success",
      states: states.sort((a, b) => a.localeCompare(b)),
      occupations: ["student", "business", "self_employed", "government_job", "private_sector_job"],
      genders: ["male", "female", "others"],
      tradingExperiences: ["beginner", "intermediate", "experienced"],
    });
  } catch (err) {
    console.error("[log] GET /admin/meta — 500:", err.message);
    res.status(500).json({ status: "error", message: "Failed to fetch filter options" });
  }
};

export const getStats = async (req, res) => {
  try {
    // India has a single fixed UTC+5:30 offset (no DST), so "today" for the
    // dashboard cards is computed as an IST calendar day — same convention
    // used for the free-chat daily reset in the main server.
    const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;
    const istNow = new Date(Date.now() + IST_OFFSET_MS);
    const startOfTodayIst = new Date(Date.UTC(istNow.getUTCFullYear(), istNow.getUTCMonth(), istNow.getUTCDate()));
    const startOfTodayUtc = new Date(startOfTodayIst.getTime() - IST_OFFSET_MS);
    const startOfWeek = new Date(startOfTodayUtc.getTime() - 6 * 24 * 60 * 60 * 1000);
    const startOfMonth = new Date(startOfTodayUtc.getTime() - 29 * 24 * 60 * 60 * 1000);

    const [total, premium, newToday, newThisWeek, newThisMonth] = await Promise.all([
      User.countDocuments({}),
      User.countDocuments({ isPremium: true }),
      User.countDocuments({ createdAt: { $gte: startOfTodayUtc } }),
      User.countDocuments({ createdAt: { $gte: startOfWeek } }),
      User.countDocuments({ createdAt: { $gte: startOfMonth } }),
    ]);

    res.json({ status: "success", total, premium, free: total - premium, newToday, newThisWeek, newThisMonth });
  } catch (err) {
    console.error("[log] GET /admin/stats — 500:", err.message);
    res.status(500).json({ status: "error", message: "Failed to fetch stats" });
  }
};

const EXPORT_COLUMNS = [
  { header: "Name", key: "name", width: 24 },
  { header: "Email", key: "email", width: 28 },
  { header: "Phone", key: "phoneNumber", width: 16 },
  { header: "State", key: "state", width: 16 },
  { header: "Occupation", key: "occupation", width: 18 },
  { header: "Trading Experience", key: "tradingExperience", width: 18 },
  { header: "Gender", key: "gender", width: 10 },
  { header: "Premium", key: "isPremium", width: 10 },
  { header: "Premium Expires", key: "premiumExpiresAt", width: 18 },
  { header: "SOB Alert", key: "isSOB_alert_premium", width: 10 },
  { header: "Xaud Alert", key: "isXaud_alert_premium", width: 10 },
  { header: "Crypto Alert", key: "isCrypto_alert_premium", width: 12 },
  { header: "Chats Today", key: "textChatCount", width: 12 },
  { header: "Devices", key: "deviceCount", width: 10 },
  { header: "Signed Up", key: "createdAt", width: 20 },
  { header: "Last Updated", key: "updatedAt", width: 20 },
  { header: "Firebase UID", key: "firebaseUid", width: 32 },
];

export const exportUsers = async (req, res) => {
  try {
    const filter = buildFilter(req.query);
    const sort = buildSort(req.query);
    // No pagination here (export dumps everything that matches the current
    // filters), but capped so a runaway request can't blow up memory.
    const users = await User.find(filter).sort(sort).limit(50000).select("-__v").lean();

    const workbook = new ExcelJS.Workbook();
    workbook.creator = "Stock Archery Admin Panel";
    workbook.created = new Date();

    const sheet = workbook.addWorksheet("Users");
    sheet.columns = EXPORT_COLUMNS;
    sheet.getRow(1).font = { bold: true };
    sheet.getRow(1).fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FFE2E8F0" } };
    sheet.autoFilter = { from: "A1", to: `${String.fromCharCode(64 + EXPORT_COLUMNS.length)}1` };
    sheet.views = [{ state: "frozen", ySplit: 1 }];

    for (const u of users) {
      sheet.addRow({
        ...u,
        isPremium: u.isPremium ? "Yes" : "No",
        isSOB_alert_premium: u.isSOB_alert_premium ? "Yes" : "No",
        isXaud_alert_premium: u.isXaud_alert_premium ? "Yes" : "No",
        isCrypto_alert_premium: u.isCrypto_alert_premium ? "Yes" : "No",
        deviceCount: Array.isArray(u.fcmTokens) ? u.fcmTokens.length : 0,
        premiumExpiresAt: u.premiumExpiresAt ? new Date(u.premiumExpiresAt).toLocaleString("en-IN") : "",
        createdAt: u.createdAt ? new Date(u.createdAt).toLocaleString("en-IN") : "",
        updatedAt: u.updatedAt ? new Date(u.updatedAt).toLocaleString("en-IN") : "",
      });
    }

    const filename = `users-export-${new Date().toISOString().slice(0, 10)}.xlsx`;
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);

    await workbook.xlsx.write(res);
    res.end();
    console.log(`[log] GET /admin/users/export — 200: ${users.length} rows`);
  } catch (err) {
    console.error("[log] GET /admin/users/export — 500:", err.message);
    // Headers may already be sent if the write started; guard against a
    // double-send crashing the process.
    if (!res.headersSent) {
      res.status(500).json({ status: "error", message: "Failed to export users" });
    } else {
      res.end();
    }
  }
};
