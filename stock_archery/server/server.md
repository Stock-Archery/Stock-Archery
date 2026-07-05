# Stock Archery — Main Server Documentation

> **Last Updated:** July 2026
> **Stack:** Node.js + Express 5, Mongoose 9.5, Firebase Admin SDK 13.10, Axios 1.6
> **Entry Point:** `server.js`
> **Default Port:** 5000
> **Body Limit:** 50mb (JSON + URL-encoded)

---

## Table of Contents

1. [Startup Flow](#1-startup-flow)
2. [Directory Structure](#2-directory-structure)
3. [Dependencies](#3-dependencies)
4. [Configuration Files](#4-configuration-files)
5. [Auth Middleware](#5-auth-middleware)
6. [Database Schema](#6-database-schema)
7. [API Endpoints](#7-api-endpoints)
8. [Controller Logic](#8-controller-logic)
9. [OpenAI Integration](#9-openai-integration)
10. [OTP Flow (2Factor.in)](#10-otp-flow-2factorin)
11. [Push Notifications (FCM)](#11-push-notifications-fcm)
12. [Environment Variables](#12-environment-variables)
13. [Security Concerns](#13-security-concerns)

---

## 1. Startup Flow

```
1. Load .env via dotenv
2. Connect to MongoDB Atlas via config/db.js (fatal on failure)
3. Init Firebase Admin SDK via config/firebase.js (graceful fallback if missing)
4. Mount route files on Express 5 app
5. Listen on PORT (default 5000)
```

---

## 2. Directory Structure

```
server/
├── server.js                          # Express app entry point
├── package.json                       # Dependencies
├── .env                               # Secrets (MONGO_URI, OPENAI_API_KEY, TWOFACTOR_API_KEY)
├── firebase-service-account.json      # Firebase Admin credentials (gitignored)
│
├── config/
│   ├── db.js                          # mongoose.connect(MONGO_URI), fatal on failure
│   └── firebase.js                    # Firebase Admin SDK init, graceful fallback
│
├── middleware/
│   └── auth.js                        # requireAuth: Bearer token → Firebase verify or mock fallback
│
├── models/
│   ├── User.js                        # users collection schema
│   ├── Recommendation.js              # recommendations collection schema
│   └── UserAlertAccess.js             # user_alert_access collection schema
│
├── routes/
│   ├── authRoutes.js                  # /api/auth/*
│   ├── userRoutes.js                  # /api/user/*
│   ├── chatRoutes.js                  # /api/chat, /api/chart-analysis
│   ├── recommendationRoutes.js        # /api/recommendations
│   └── notificationRoutes.js          # /api/test/push, /api/admin/push/broadcast
│
└── controllers/
    ├── authController.js              # sendOtp, syncUser
    ├── userController.js              # registerDevice, unregisterDevice, updateAlertAccess
    ├── chatController.js              # chat, chartAnalysis
    ├── recommendationController.js    # getRecommendations
    └── notificationController.js      # testPush, broadcastPush
```

---

## 3. Dependencies

| Package | Version | Purpose |
|---|---|---|
| express | ^5.2.1 | Web framework (Express 5) |
| mongoose | ^9.5.0 | MongoDB ODM |
| firebase-admin | ^13.10.0 | Firebase Admin SDK (Auth, FCM, RTDB) |
| axios | ^1.6.0 | HTTP client (OpenAI, 2Factor.in) |
| cors | ^2.8.6 | Cross-origin resource sharing |
| dotenv | ^17.4.2 | Environment variables |

**No test suite.** `"test": "echo \"Error: no test specified\" && exit 1"`

---

## 4. Configuration Files

### config/db.js
```js
const mongoose = require('mongoose');
const connectDB = async () => {
  if (!process.env.MONGO_URI) {
    console.error("FATAL ERROR: MONGO_URI is not defined.");
    process.exit(1);
  }
  await mongoose.connect(process.env.MONGO_URI);
};
module.exports = connectDB;
```
- Connects to MongoDB Atlas
- Exits process on failure (no retry logic)

### config/firebase.js
```js
const admin = require('firebase-admin');
const initFirebase = () => {
  const serviceAccount = require('../firebase-service-account.json');
  if (serviceAccount.project_id && serviceAccount.project_id !== "YOUR_PROJECT_ID") {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  }
};
module.exports = { admin, initFirebase };
```
- Loads `firebase-service-account.json` from server root
- Skips init if file missing or contains placeholder values
- Exports `admin` instance for use in middleware and controllers
- Console warns when running in fallback mode

---

## 5. Auth Middleware (middleware/auth.js)

```js
async function requireAuth(req, res, next) {
  // 1. Extract Bearer token from Authorization header
  // 2. If Firebase Admin initialized → verifyIdToken(token) → set req.user
  // 3. If Firebase not initialized (dev) → accept mock-uid-* tokens
  // 4. Returns 401 on missing/invalid token
}
```

**Behavior:**
- Firebase mode: verifies JWT via `admin.auth().verifyIdToken(token)`
- Dev/mock mode: accepts tokens starting with `mock-uid-*`, generates synthetic `req.user = { uid, email }`
- Used on: `POST /auth/sync`, `POST /user/device/register`, `POST /user/device/unregister`, `POST /test/push`, `POST /admin/push/broadcast`

---

## 6. Database Schema

### Collection: `users`

| Field | Type | Constraints | Default |
|---|---|---|---|
| `firebaseUid` | String | required, unique, indexed | — |
| `name` | String | required, trimmed | — |
| `email` | String | required, unique, lowercase, trimmed | — |
| `phoneNumber` | String | required, trimmed | — |
| `location` | String | required, trimmed | — |
| `isPremium` | Boolean | — | `false` |
| `premiumExpiresAt` | Date | — | `null` |
| `fcmTokens` | Array of subdocs | — | `[]` |
| `createdAt` | Date | auto | timestamps |
| `updatedAt` | Date | auto | timestamps |

**`fcmTokens[]` subdocument:**

| Field | Type | Default |
|---|---|---|
| `token` | String | required |
| `deviceId` | String | required |
| `platform` | String | — |
| `isActive` | Boolean | `true` |
| `updatedAt` | Date | `Date.now` |

### Collection: `recommendations`

| Field | Type | Notes |
|---|---|---|
| `type` | String | Queried as `"current_recommendations"` |
| `stocks` | `[String]` | List of stock ticker/names |
| `updatedAt` | String | Stored as String, not Date |

### Collection: `user_alert_access`

| Field | Type | Default |
|---|---|---|
| `firebaseUid` | String | required, unique, indexed |
| `isSOB_alert_premium` | Boolean | `false` |
| `SOB_alert_expiresAt` | Date | `null` |
| `isXaud_alert_premium` | Boolean | `false` |
| `Xaud_alert_expiresAt` | Date | `null` |
| `isCrypto_alert_premium` | Boolean | `false` |
| `Crypto_alert_expiresAt` | Date | `null` |
| `createdAt` | Date | auto |
| `updatedAt` | Date | auto |

---

## 7. API Endpoints

### Health Check

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/` | No | Returns `{ status: "ok", message: "Stock Archery Main Server" }` |

### Auth Routes (`/api/auth`)

| Method | Path | Auth | Body | Response | Description |
|---|---|---|---|---|---|
| POST | `/api/auth/send-otp` | No | `{ phoneNumber }` | `{ success, message, otp }` | Sends OTP via 2Factor.in API (AUTOGEN2 mode). Returns OTP in response body. |
| POST | `/api/auth/sync` | Yes | `{ name, phoneNumber, location }` (new) or `{}` (existing) | `{ status, user, alertAccess }` | Upserts user in MongoDB. Creates UserAlertAccess if missing. Auto-expires past-due alert subscriptions. |

### User Routes (`/api/user`)

| Method | Path | Auth | Body | Response | Description |
|---|---|---|---|---|---|
| POST | `/api/user/device/register` | Yes | `{ token, deviceId, platform }` | `{ status, message }` | Adds/updates FCM token in `fcmTokens[]` array (matched by `deviceId`). |
| POST | `/api/user/device/unregister` | Yes | `{ deviceId }` | `{ status, message }` | Sets `isActive = false` on matching FCM token entry. |
| PUT | `/api/user/alert-access/:firebaseUid` | **No** | `{ isSOB_alert_premium?, isXaud_alert_premium?, isCrypto_alert_premium? }` | `{ status, message, alertAccess }` | Toggles alert flags. `true` → sets 1-year expiry from now. `false` → clears expiry and flag. **No auth middleware.** |

### Recommendation Routes (`/api/recommendations`)

| Method | Path | Auth | Response | Description |
|---|---|---|---|---|
| GET | `/api/recommendations` | No | `["STOCK1", "STOCK2", ...]` or 404 | Returns `stocks` array from `{ type: 'current_recommendations' }`. |

### Chat Routes (`/api`)

| Method | Path | Auth | Body | Response | Description |
|---|---|---|---|---|---|
| POST | `/api/chat` | No | `{ message }` | `{ reply, citations, usedWebSearch, brokenToolContinuation, rawOutput }` | Sends to OpenAI GPT-4o Responses API with `web_search_preview` tool. Auto-retries once on broken tool continuation. |
| POST | `/api/chart-analysis` | No | `{ message, image }` (base64) | `{ reply, citations, usedWebSearch, brokenToolContinuation, rawOutput }` | Sends to GPT-4o Responses API with text + image input. No web search. Appends "educational purposes only" disclaimer. Max 1500 tokens. |

### Notification Routes (`/api`)

| Method | Path | Auth | Body | Response | Description |
|---|---|---|---|---|---|
| POST | `/api/test/push` | Yes | `{ title, body }` | `{ status, response }` | Sends FCM push to all active tokens of the authenticated user via `sendEachForMulticast`. Auto-deactivates invalid tokens. |
| POST | `/api/admin/push/broadcast` | Yes | `{ title, body }` | `{ status, messageId }` | Sends FCM push to `all_users` topic. **No admin role check.** |

---

## 8. Controller Logic

### authController.js

**sendOtp(phoneNumber)**
- Calls `https://2factor.in/API/V1/{apiKey}/SMS/{phoneNumber}/AUTOGEN2/`
- Returns OTP in response body (security concern — should be SMS-only)
- Used during phone signup flow

**syncUser(uid, email, name, phoneNumber, location)**
- Finds user by `firebaseUid` in MongoDB
- New user: creates document with all required fields
- Existing user: optionally updates `name`, `phoneNumber`, `location`
- Finds or creates `UserAlertAccess` document
- Auto-expires past-due alert subscriptions (compares dates to `new Date()`)
- Returns `{ status, user, alertAccess }`

### userController.js

**registerDevice(uid, token, deviceId, platform)**
- Finds user by `firebaseUid`
- If `deviceId` exists in `fcmTokens[]`: updates token, platform, isActive, updatedAt
- If new deviceId: pushes new subdocument

**unregisterDevice(uid, deviceId)**
- Sets `isActive = false` on matching `fcmTokens[]` entry

**updateAlertAccess(firebaseUid, body)**
- Finds or creates `UserAlertAccess` document
- For each flag (`isSOB_alert_premium`, `isXaud_alert_premium`, `isCrypto_alert_premium`):
  - `true` → sets flag + 1-year expiry from now
  - `false` → clears flag + sets expiry to null
- **No auth middleware on this endpoint**

### recommendationController.js

**getRecommendations()**
- Queries `{ type: 'current_recommendations' }` from `recommendations` collection
- Returns just the `stocks` array
- 404 if no document found

### chatController.js

**chat(message)**
- Calls OpenAI GPT-4o Responses API with `web_search_preview` tool
- Parses output array for text, citations, web search status
- Detects "broken tool continuation" (web search ran but no message) → auto-retry once
- Returns `{ reply, citations, usedWebSearch, brokenToolContinuation, rawOutput }`

**chartAnalysis(message, image)**
- Calls OpenAI GPT-4o Responses API with text + base64 image input
- No web search tool
- Appends mandatory "educational purposes only" disclaimer
- Max 1500 output tokens
- Same broken-tool-continuation retry logic

### notificationController.js

**sendPushNotification(user, title, body, data)**
- Filters active FCM tokens from `user.fcmTokens[]`
- Uses `admin.messaging().sendEachForMulticast()`
- Auto-deactivates tokens returning `invalid-registration-token` or `registration-token-not-registered` errors
- Also exported for reuse

**testPush(uid, title, body)**
- Finds user by `firebaseUid`, calls `sendPushNotification()`

**broadcastPush(title, body)**
- Sends to `all_users` FCM topic via `admin.messaging().send()`
- **No admin role verification**

---

## 9. OpenAI Integration

**Model:** GPT-4o via OpenAI **Responses API** (`/v1/responses` — NOT Chat Completions)

**Shared config:**
| Parameter | Value |
|---|---|
| Model | `gpt-4o` |
| Temperature | 0.4 |
| Top-p | 0.9 |
| Endpoint | `https://api.openai.com/v1/responses` |
| Auth | `Bearer ${process.env.OPENAI_API_KEY}` |

### Chat endpoint
- System prompt: "Stock Archery AI" — finance/markets expert persona
- Uses `web_search_preview` tool for real-time market data
- Max output tokens: 1000
- Input: `[{ role: "user", content: [{ type: "input_text", text: message }] }]`

### Chart analysis endpoint
- Same system prompt with chart-specific rules
- No web search tool
- Max output tokens: 1500
- Input: text + `input_image` (base64 data URI)
- Mandatory disclaimer appended to every response

### Response parser (`parseOpenAIResponse`)
- Iterates `output[]` array
- Detects `web_search_call` items
- Extracts `message` items with `output_text` content
- Extracts `url_citation` annotations
- Returns `{ reply, citations, usedWebSearch, hasMessage, brokenToolContinuation, rawOutput }`

### Broken tool continuation
- Detected when `usedWebSearch=true` and `hasMessage=false`
- Auto-retries once with same request
- Returns fallback message if retry also fails

---

## 10. OTP Flow (2Factor.in)

```
1. Client sends POST /api/auth/send-otp with { phoneNumber }
2. Server calls: https://2factor.in/API/V1/{apiKey}/SMS/{phoneNumber}/AUTOGEN2/
3. 2Factor.in sends SMS to user
4. Server returns OTP in response body (security concern)
5. Client completes Firebase phone auth verification
6. Client then calls POST /api/auth/sync to create/update user in MongoDB
```

**Template:** `AUTOGEN2` (6-digit auto-generated OTP)

---

## 11. Push Notifications (FCM)

**Registration:**
- On login, client calls `POST /api/user/device/register` with FCM token + deviceId + platform
- Token stored in `user.fcmTokens[]` array (supports multiple devices)

**Targeted push:**
- `POST /api/test/push` sends to specific user's active tokens
- Uses `sendEachForMulticast()` for multi-device delivery
- Invalid/expired tokens auto-deactivated

**Broadcast push:**
- `POST /api/admin/push/broadcast` sends to `all_users` FCM topic
- Uses `send()` with topic-based delivery

**Token cleanup:**
- On failed delivery, checks error code
- `messaging/invalid-registration-token` or `messaging/registration-token-not-registered` → sets `isActive = false`

---

## 12. Environment Variables

### Required

| Variable | Example | Notes |
|---|---|---|
| `MONGO_URI` | `mongodb+srv://...` | **Fatal if missing** — process exits |
| `OPENAI_API_KEY` | `sk-proj-...` | For GPT-4o chat + chart analysis |
| `TWOFACTOR_API_KEY` | `e6ec9604-...` | 2Factor.in SMS OTP API key |

### Optional

| Variable | Default | Notes |
|---|---|---|
| `PORT` | `5000` | Server listen port |

### Firebase

- Requires `firebase-service-account.json` in server root
- Falls back to dev/mock mode if missing

---

## 13. Security Concerns

| # | Issue | Severity | Location | Details |
|---|---|---|---|---|
| 1 | **Unprotected alert-access endpoint** | HIGH | `userRoutes.js:8` | `PUT /api/user/alert-access/:firebaseUid` has no auth middleware. Anyone can grant/revoke premium for any user. |
| 2 | **No admin check on broadcast** | MEDIUM | `notificationController.js` | Any authenticated user can push to all users via `/api/admin/push/broadcast`. |
| 3 | **Unprotected AI endpoints** | MEDIUM | `chatRoutes.js` | `/api/chat` and `/api/chart-analysis` have no auth or rate limiting. Anyone can consume OpenAI credits. |
| 4 | **OTP returned in response** | MEDIUM | `authController.js` | OTP should only be sent via SMS, not returned in API response body. |
| 5 | **No rate limiting anywhere** | MEDIUM | All routes | Vulnerable to abuse. No `express-rate-limit` configured. |
| 6 | **No input validation** | MEDIUM | All controllers | No `joi` or `zod` validation. Relies on manual `if (!field)` checks. |
| 7 | **Mock auth accepts any mock-uid-*** | LOW | `middleware/auth.js` | Accepts any token starting with `mock-uid-`. Acceptable in dev only. |
| 8 | **Live secrets in .env** | LOW | `.env` files | Should rotate keys and use git-secrets. |

---

## Full Request Flow: User Signup → Login → Use Features

```
1. User opens app → AuthWrapper → LoginView
2. User taps "Sign Up" → SignupView (Step 1: Name + Phone)
3. Client calls POST /api/auth/send-otp → 2Factor.in SMS → OTP in response
4. User enters OTP → Firebase phone auth verification
5. User completes profile (Email + Location + Password) → Firebase createUserWithEmailAndPassword
6. Firebase ID token obtained → POST /api/auth/sync with profile data
7. Server upserts User + UserAlertAccess in MongoDB → returns user + alertAccess
8. Client stores user in authProvider (alertAccess currently discarded — see client docs)
9. FCM token registered via POST /api/user/device/register
10. Session ID written to Firebase RTDB at active_sessions/{uid}
11. MainNavigationScreen loads (5 tabs + drawer)
12. User navigates tabs → stocks fetched via GET /api/recommendations
13. User sends AI chat → POST /api/chat → OpenAI GPT-4o + web search
14. User uploads chart → POST /api/chart-analysis → GPT-4o vision
```
