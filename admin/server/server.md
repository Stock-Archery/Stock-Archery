# Stock Archery — Admin Server Documentation

> **Last Updated:** July 2026
> **Stack:** Node.js + Express 5, ESM Modules, Mongoose 9.5, Axios 1.15, zlib (built-in)
> **Entry Point:** `index.js`
> **Default Port:** 3000

---

## Table of Contents

1. [Overview](#1-overview)
2. [Directory Structure](#2-directory-structure)
3. [Dependencies](#3-dependencies)
4. [MongoDB Schema](#4-mongodb-schema)
5. [In-Memory Cache](#5-in-memory-cache)
6. [API Endpoints](#6-api-endpoints)
7. [Data Fetch Flow (Upstox)](#7-data-fetch-flow-upstox)
8. [Startup Behavior](#8-startup-behavior)
9. [Environment Variables](#9-environment-variables)

---

## 1. Overview

The admin server is a microservice responsible for one thing: fetching F&O (Futures & Options) stock instruments from Upstox, filtering them, and storing them in MongoDB. The admin Flutter client then reads directly from MongoDB (bypassing this server) to display the stock list for the admin to select top 5 recommendations.

**What this server does:**
- Fetches NSE instrument data from Upstox (gzipped JSON)
- Filters for `NSE_FO` segment instruments
- Extracts unique `underlying_symbol` values
- Stores the sorted list in MongoDB `fnostocks` collection
- Serves the list via API

**What this server does NOT do:**
- Does not manage users
- Does not handle authentication
- Does not select/publish top 5 recommendations
- Does not manage alert access or premium flags
- Does not interact with OpenAI or any AI services

---

## 2. Directory Structure

```
admin/server/
├── index.js                   # Express server (ESM), 122 lines — single file app
├── package.json               # type: "module" for ESM
├── .env                       # mongoUri (gitignored)
├── .gitignore                 # node_modules, .env
└── node_modules/
```

**Total:** 1 JavaScript file. No routes directory, no controllers directory, no models directory — everything is in `index.js`.

---

## 3. Dependencies

| Package | Version | Purpose |
|---|---|---|
| express | ^5.2.1 | Web framework (Express 5) |
| mongoose | ^9.5.0 | MongoDB ODM |
| axios | ^1.15.2 | HTTP client (fetches Upstox data) |
| cors | ^2.8.6 | Cross-origin resource sharing |
| dotenv | ^17.4.2 | Environment variables |
| zlib | built-in | Decompresses gzip response from Upstox |

**Module system:** ESM (`"type": "module"` in package.json). Uses `import/export` syntax.

**No test suite.** `"test": "echo \"Error: no test specified\" && exit 1"`

---

## 4. MongoDB Schema

### Collection: `fnostocks`

Defined inline in `index.js`:

```js
const fnoStockSchema = new mongoose.Schema({
    symbol: { type: String, unique: true },
    updatedAt: { type: Date, default: Date.now }
});
const FnoStock = mongoose.model("FnoStock", fnoStockSchema);
```

| Field | Type | Constraints | Default |
|---|---|---|---|
| `symbol` | String | unique index | — |
| `updatedAt` | Date | — | `Date.now` |

**Only collection this server uses.** The main server's `recommendations` collection is written to directly by the admin Flutter client (not this server).

---

## 5. In-Memory Cache

```js
let cache = {
    data: [],        // Array of stock symbol strings
    lastUpdated: null // Date object
};
```

- Populated on startup and after each refresh
- `GET /fno-stocks` serves from cache first, falls back to DB if cache is empty
- `POST /refresh-fno` updates cache after fetching from Upstox
- Avoids hitting MongoDB on every GET request

---

## 6. API Endpoints

### Health Check

| Method | Route | Description |
|---|---|---|
| GET | `/` | Returns `{ status: "ok", message: "Stock Archery Server is running" }` |

### Get F&O Stocks

| Method | Route | Description |
|---|---|---|
| GET | `/fno-stocks` | Returns cached F&O stock list |

**Response:**
```json
{
  "count": 250,
  "lastUpdated": "2026-07-05T10:30:00.000Z",
  "stocks": ["AARTIIND", "ABB", "ABBOTINDIA", ...]
}
```

**Behavior:**
1. If cache has data → return from cache
2. If cache empty → query `fnostocks` collection, sort by symbol, populate cache, return
3. If both empty → returns `{ count: 0, lastUpdated: null, stocks: [] }`

### Refresh F&O Data

| Method | Route | Description |
|---|---|---|
| POST | `/refresh-fno` | Fetches fresh data from Upstox, updates DB and cache |

**Response:**
```json
{
  "message": "F&O list refreshed and stored in MongoDB successfully",
  "count": 250,
  "lastUpdated": "2026-07-05T10:30:00.000Z"
}
```

**Behavior:**
1. Fetches gzipped JSON from Upstox
2. Decompresses and parses
3. Filters for `segment === "NSE_FO"` with `underlying_symbol`
4. Extracts unique symbols into a sorted array
5. Wipes entire `fnostocks` collection (`deleteMany({})`)
6. Bulk inserts new list (`insertMany`)
7. Updates in-memory cache

---

## 7. Data Fetch Flow (Upstox)

### Source URL
```
https://assets.upstox.com/market-quote/instruments/exchange/NSE.json.gz
```

### Processing Pipeline

```
1. GET Upstox URL (responseType: arraybuffer)
       ↓
2. zlib.gunzipSync(response.data).toString()
       ↓
3. JSON.parse(decompressed)
       ↓
4. Filter: item.segment === "NSE_FO" && item.underlying_symbol
       ↓
5. Extract unique underlying_symbol values via Set
       ↓
6. Convert to sorted array
       ↓
7. Delete all documents in fnostocks collection
       ↓
8. Insert new documents (bulk insert)
       ↓
9. Update in-memory cache
```

### What Upstox data looks like (before filtering)
Each item in the JSON array represents an NSE instrument:
```json
{
  "segment": "NSE_FO",
  "underlying_symbol": "RELIANCE",
  "tradingsymbol": "RELIANCE24JULFUT",
  ...
}
```

Only `segment` and `underlying_symbol` are used. The `underlying_symbol` is the parent stock name (e.g., RELIANCE, TCS, INFY) — not the specific F&O contract.

---

## 8. Startup Behavior

```
1. Load .env via dotenv
2. Connect to MongoDB Atlas (logs success/error, does NOT exit on failure)
3. Define FnoStock model
4. Call fetchAndStoreFNOData() immediately
   - Fetches from Upstox
   - Populates fnostocks collection
   - Populates in-memory cache
5. Mount routes
6. Listen on PORT (default 3000)
```

**Note:** Unlike the main server, this server does NOT exit on MongoDB connection failure — it logs the error and continues (may fail on requests).

---

## 9. Environment Variables

| Variable | Required | Default | Example |
|---|---|---|---|
| `mongoUri` | Yes | — | `mongodb+srv://user:pass@cluster.mongodb.net/stock_archery` |
| `PORT` | No | `3000` | `3000` |

**Database:** Same MongoDB Atlas cluster as the main server (`stock_archery` database).

**Note:** The env variable is named `mongoUri` (camelCase), not `MONGO_URI` like the main server.

---

## Data Flow: Full Admin Pipeline

```
Upstox API (NSE instruments JSON.gz)
    ↓  POST /refresh-fno
Admin Server (Node.js)
    ↓  Mongoose writes
MongoDB Atlas (fnostocks collection)
    ↓  mongo_dart direct read
Admin Flutter Client
    ↓  Provider: StockViewModel
Flutter UI (stock_selection_page.dart)
    ↓  mongo_dart direct write
MongoDB Atlas (recommendations collection)
    ↓  GET /api/recommendations
Main Server
    ↓  returns stocks array
Main Client (end-user app)
```

**Key insight:** The admin server only handles steps 1-3. Steps 4-7 are handled by the admin Flutter client writing directly to MongoDB.
