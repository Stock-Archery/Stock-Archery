import express from "express";
import axios from "axios";
import zlib from "zlib";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";
import alertRoutes from "./routes/alertRoutes.js";
import userRoutes from "./routes/userRoutes.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));

const PORT = process.env.PORT || 3000;

// Mount routes
app.use("/alerts", alertRoutes);
app.use("/users", userRoutes);

app.get("/", (req, res) => {
    res.json({ status: "ok", message: "Stock Archery Server is running" });
});
const MONGO_URI = process.env.mongoUri;
const DATA_URL = "https://assets.upstox.com/market-quote/instruments/exchange/NSE.json.gz";

// Connect to MongoDB
mongoose.connect(MONGO_URI)
    .then(() => console.log("Connected to MongoDB Atlas"))
    .catch(err => console.error("MongoDB connection error:", err));

// Define Schema for F&O Stocks
const fnoStockSchema = new mongoose.Schema({
    symbol: { type: String, unique: true },
    updatedAt: { type: Date, default: Date.now }
});

const FnoStock = mongoose.model("FnoStock", fnoStockSchema);

let cache = {
    data: [],
    lastUpdated: null
};

// 🔥 Fetch + parse + store in DB
async function fetchAndStoreFNOData() {
    try {
        console.log("Fetching F&O data from Upstox...");

        const response = await axios.get(DATA_URL, {
            responseType: "arraybuffer"
        });

        const decompressed = zlib.gunzipSync(response.data).toString();
        const json = JSON.parse(decompressed);

        const fnoSet = new Set();

        for (let item of json) {
            if (item.segment === "NSE_FO" && item.underlying_symbol) {
                fnoSet.add(item.underlying_symbol);
            }
        }

        const stocksArray = Array.from(fnoSet).sort();
        
        console.log(`Found ${stocksArray.length} F&O stocks. Updating database...`);

        // Update database: Clear and insert new list or upsert
        // For simplicity, we can clear and insert or use bulkWrite
        // Let's use a simple approach: clear and re-insert
        await FnoStock.deleteMany({});
        const stockDocs = stocksArray.map(symbol => ({ symbol }));
        await FnoStock.insertMany(stockDocs);

        cache.data = stocksArray;
        cache.lastUpdated = new Date();

        console.log(`Database updated: ${cache.data.length} F&O stocks`);
    } catch (err) {
        console.error("Error:", err.message);
        throw err;
    }
}

// ⚡ Initial load
// fetchAndStoreFNOData().catch(err => console.error("Initial fetch failed:", err));


// 📡 GET current cached list (or from DB)
app.get("/fno-stocks", async (req, res) => {
    try {
        if (cache.data.length === 0) {
            const stocksFromDb = await FnoStock.find().sort({ symbol: 1 });
            cache.data = stocksFromDb.map(s => s.symbol);
            cache.lastUpdated = cache.data.length > 0 ? new Date() : null;
        }
        
        res.json({
            count: cache.data.length,
            lastUpdated: cache.lastUpdated,
            stocks: cache.data
        });
    } catch (err) {
        res.status(500).json({ error: "Failed to fetch stocks from DB" });
    }
});


// 🔁 Manual refresh endpoint
app.post("/refresh-fno", async (req, res) => {
    try {
        await fetchAndStoreFNOData();
        res.json({
            message: "F&O list refreshed and stored in MongoDB successfully",
            count: cache.data.length,
            lastUpdated: cache.lastUpdated
        });
    } catch (err) {
        res.status(500).json({ error: "Refresh failed" });
    }
});


app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
