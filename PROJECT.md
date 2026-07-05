# Stock Archery — Complete Project Documentation

> **Last Updated:** July 2026
> **Purpose:** Single-source-of-truth reference for AI agents and developers to understand the entire codebase without re-scanning files.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Tech Stack](#3-tech-stack)
4. [Design System: Aureum Elite](#4-design-system-aureum-elite)
5. [Main Client (Flutter App)](#5-main-client-flutter-app)
6. [Main Server (Backend API)](#6-main-server-backend-api)
7. [Admin Client (Flutter Dashboard)](#7-admin-client-flutter-dashboard)
8. [Admin Server (F&O Data Service)](#8-admin-server-fo-data-service)
9. [Database Schema](#9-database-schema)
10. [API Endpoints](#10-api-endpoints)
11. [Authentication Flow](#11-authentication-flow)
12. [State Management (Riverpod Providers)](#12-state-management-riverpod-providers)
13. [Key Business Logic](#13-key-business-logic)
14. [Security Concerns](#14-security-concerns)
15. [Environment Variables](#15-environment-variables)
16. [Deployment](#16-deployment)

---

## 1. Project Overview

**Stock Archery** is a premium stock trading education and AI-powered analysis platform targeting high-net-worth aspiring traders in India. The platform provides:

- **Stock Recommendations:** Admin-curated top 5 F&O stocks delivered to users
- **AI Trading Bot:** GPT-4o powered chat with real-time web search for market insights
- **AI Chart Analysis:** GPT-4o vision for image-based technical chart analysis
- **Video Education:** Curated YouTube strategy videos
- **Premium Subscriptions:** RevenueCat-managed annual plan with gated content
- **Single-Device Login:** Enforced via Firebase Realtime Database
- **Push Notifications:** FCM-based targeted and broadcast messaging
- **Broker Partnerships:** Affiliate links to Fyers, CoinDCX, Angel One, Dhan, Upstox

---

## 2. Repository Structure

```
Stock-Archery/
├── README.md                          # API documentation for both servers
├── DESIGN.md                          # "Aureum Elite" design system specification
├── PROJECT.md                         # This file — complete project reference
│
├── stock_archery/                     # Main application
│   ├── client/                        # Flutter mobile/web app (end-user facing)
│   │   ├── lib/                       # Dart source code
│   │   ├── android/                   # Android platform files
│   │   ├── ios/                       # iOS platform files
│   │   ├── web/                       # Web platform files
│   │   ├── linux/                     # Linux desktop files
│   │   ├── macos/                     # macOS desktop files
│   │   ├── windows/                   # Windows desktop files
│   │   ├── assets/                    # App icons, logo images
│   │   ├── test/                      # Flutter tests
│   │   ├── pubspec.yaml               # Flutter dependencies
│   │   ├── analysis_options.yaml      # Dart lint rules
│   │   ├── .env                       # Environment variables (gitignored)
│   │   └── firebase.json              # Firebase hosting config
│   │
│   └── server/                        # Node.js backend API
│       ├── server.js                  # Express app entry point
│       ├── config/                    # DB + Firebase initialization
│       ├── middleware/                 # Auth middleware
│       ├── models/                    # Mongoose schemas
│       ├── routes/                    # Express route definitions
│       ├── controllers/               # Request handlers + business logic
│       ├── .env                       # Secrets (gitignored)
│       ├── firebase-service-account.json  # Firebase credentials (gitignored)
│       └── package.json               # Node dependencies
│
├── admin/                             # Admin panel
│   ├── client/admin/                  # Flutter admin dashboard
│   │   ├── lib/                       # Dart source code
│   │   ├── pubspec.yaml               # Flutter dependencies
│   │   ├── .env                       # SERVER_URL + mongoUri (gitignored)
│   │   └── .env.sample                # Template for .env
│   │
│   ├── server/                        # F&O stock data microservice
│   │   ├── index.js                   # Express server (fetches from Upstox)
│   │   ├── .env                       # mongoUri (gitignored)
│   │   └── package.json               # Node dependencies (ESM)
│   │
│   └── test.txt                       # Placeholder file
│
└── .vscode/                           # VS Code workspace settings
```

---

## 3. Tech Stack

### Main Client
| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter | SDK ^3.9.2 |
| Language | Dart | ^3.9.2 |
| State Management | flutter_riverpod | ^2.6.1 |
| Authentication | firebase_auth | ^5.1.0 |
| Push Notifications | firebase_messaging | ^15.2.10 |
| Session Enforcement | firebase_database | ^11.3.10 |
| Subscriptions | purchases_flutter (RevenueCat) | ^10.2.0 |
| HTTP Client | http | ^1.2.1 |
| Environment | flutter_dotenv | ^6.0.1 |
| Video Player | youtube_player_flutter | ^9.1.3 |
| Chat UI | dash_chat_2 | ^0.0.21 |
| Markdown | flutter_markdown | ^0.7.5 |
| Image Picker | image_picker | ^1.1.2 |
| Typography | google_fonts | ^6.2.1 |
| Local Storage | shared_preferences | ^2.5.5 |
| Device Info | device_info_plus | ^12.4.0 |
| URL Launching | url_launcher | ^6.3.1 |
| Date Formatting | intl | ^0.19.0 |
| Toasts | fluttertoast | ^8.2.10 |

### Main Server
| Category | Technology | Version |
|----------|-----------|---------|
| Runtime | Node.js | — |
| Framework | Express | ^5.2.1 |
| Database ODM | Mongoose | ^9.5.0 |
| Auth | firebase-admin | ^13.10.0 |
| HTTP Client | axios | ^1.6.0 |
| CORS | cors | ^2.8.6 |
| Env Vars | dotenv | ^17.4.2 |
| AI | OpenAI GPT-4o (Responses API) | — |
| OTP | 2Factor.in SMS API | — |

### Admin Client
| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter | (latest) |
| State Management | provider | ^6.1.5+1 |
| Database (direct) | mongo_dart | ^0.10.8 |
| HTTP | http | ^1.6.0 |
| Typography | google_fonts | ^8.0.2 |

### Admin Server
| Category | Technology | Version |
|----------|-----------|---------|
| Runtime | Node.js | ESM modules |
| Framework | Express | ^5.2.1 |
| Database ODM | Mongoose | ^9.5.0 |
| HTTP Client | axios | ^1.15.2 |
| Compression | zlib (built-in) | — |

---

## 4. Design System: Aureum Elite

Defined in `DESIGN.md`. Premium dark-theme design targeting high-net-worth traders.

### Color Palette
| Token | Hex | Usage |
|-------|-----|-------|
| surface / background | `#16130b` | Primary canvas |
| surface-container-lowest | `#110e07` | Deepest layer |
| primary / surface-tint | `#f2ca50` / `#e9c349` | Gold accents, CTAs |
| primary-container | `#d4af37` | Premium elements |
| on-surface | `#eae1d4` | Primary text |
| on-surface-variant | `#d0c5af` | Secondary text |
| outline | `#99907c` | Borders, metadata |
| outline-variant | `#4d4635` | Subtle borders |
| secondary | `#bdc7d6` | Secondary actions |
| error | `#ffb4ab` | Error states |
| surface-bright | `#3d392f` | Elevated surfaces |

### Typography
| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| display-lg | Montserrat | 48px | 700 | Hero headings |
| headline-lg | Montserrat | 32px | 600 | Section headings |
| headline-lg-mobile | Montserrat | 24px | 600 | Mobile headings |
| title-md | Montserrat | 20px | 600 | Card titles |
| body-lg | Inter | 16px | 400 | Body text |
| body-md | Inter | 14px | 400 | Secondary text |
| label-sm | Inter | 12px | 500 | Labels, captions |

### Spacing (8px Grid)
| Token | Value |
|-------|-------|
| xs | 4px |
| sm | 8px |
| md | 16px |
| lg | 24px |
| xl | 32px |
| xxl | 48px |
| container-margin-mobile | 20px |
| container-margin-desktop | 48px |
| gutter | 24px |
| card-padding | 24px |

### Border Radii
| Token | Value |
|-------|-------|
| sm | 4px (0.25rem) |
| DEFAULT | 8px (0.5rem) |
| md | 12px (0.75rem) |
| lg | 16px (1rem) |
| xl | 24px (1.5rem) |
| full | 9999px |

### Elevation Layers
1. **Level 0 (Background):** Deep Obsidian `#0B0E11`
2. **Level 1 (Cards):** Pure Black `#000000` + 1px border at 10% opacity
3. **Level 2 (Overlays):** Glassmorphism — 60% black + 20px backdrop blur
4. **Level 3 (Interaction):** Gold-tinted outer glow (8px blur, 20% opacity)

### Core Principles
- **Exclusivity:** Heavy pure black makes gold elements feel rare
- **Precision:** Mathematical spacing, razor-sharp typography
- **Tactile Digitalism:** Frosted glass simulates high-end hardware interfaces

---

## 5. Main Client (Flutter App)

### File Tree
```
stock_archery/client/lib/
├── main.dart                                    # Entry point: Firebase + RevenueCat init, runApp
├── firebase_options.dart                        # Auto-generated Firebase config
│
├── Features/
│   └── payment/
│       ├── model/
│       │   └── premium_state.dart               # PremiumState data class
│       ├── view_model/
│       │   ├── offering_provider.dart            # FutureProvider: RevenueCat offerings
│       │   └── premium_provider.dart             # StateNotifier: purchase + entitlement
│       └── view/
│           └── paywall.dart                      # PaywallScreen (alternate paywall UI)
│
├── models/
│   ├── broker_model.dart                         # BrokerModel: name, description, affiliateUrl, imageUrl
│   ├── user_model.dart                           # UserModel: firebaseUid, name, email, phone, location, isPremium
│   └── video_model.dart                          # VideoModel: title, videoId, thumbnail, description
│
├── services/
│   ├── app_config.dart                           # AppConfig: DEV_BASE_URL / PROD_BASE_URL from .env
│   ├── auth_service.dart                         # AuthService: Firebase Auth + mock fallback + backend sync
│   ├── session_service.dart                      # SessionService: single-device enforcement via Firebase RTDB
│   └── stocks_service.dart                       # StocksService: GET /api/recommendations
│
├── utils/
│   ├── toast_util.dart                           # ToastUtil: animated overlay toasts
│   └── design_system/
│       ├── design_system.dart                    # Barrel export
│       ├── app_colors.dart                       # AppColors token class
│       ├── app_spacing.dart                      # AppSpacing + AppRadii
│       └── app_typography.dart                   # AppTypography
│
├── viewmodels/
│   ├── auth_viewmodel.dart                       # AuthViewModel: login, signup, logout, forceLogout, FCM
│   ├── chat_viewmodel.dart                       # ChatViewModel: text + chart AI chat
│   ├── navigation_viewmodel.dart                 # navigationProvider: bottom nav tab index
│   ├── session_provider.dart                     # sessionProvider: RTDB session listener orchestrator
│   ├── settings_viewmodel.dart                   # SettingsViewModel: theme + language (SharedPreferences)
│   ├── stocks_viewmodel.dart                     # recommendationsProvider: FutureProvider wrapping StocksService
│   └── video_viewmodel.dart                      # videoProvider: hardcoded 3 VideoModel entries
│
├── views/
│   ├── auth_wrapper.dart                         # Root router: LoginView or MainNavigationScreen
│   ├── login_view.dart                           # Email/password login form
│   ├── signup_view.dart                          # 2-step signup (OTP phone, then profile)
│   ├── main_navigation_screen.dart               # Scaffold + BottomNav + Drawer
│   ├── stocks_view.dart                          # Top recommendations list + premium card
│   ├── ai_bot_view.dart                          # Dual-tab chat (Trading + Chart Insights)
│   ├── brokers_view.dart                         # Broker partner cards
│   ├── settings_view.dart                        # Theme, language, notifications, account, logout
│   ├── subscription_view.dart                    # Premium plan card + purchase flow
│   ├── video_list_view.dart                      # Strategy video list + premium locked card
│   └── video_player_screen.dart                  # YouTube player + metadata
│
└── widgets/
    └── build_Feature.dart                        # FeatureCard + PaymentDetailRow widgets
```

**Total:** 34 Dart files across 12 directories.

### App Screens (5 Tabs + Auxiliaries)

| Tab | Screen | Purpose |
|-----|--------|---------|
| 1 | `VideoListView` | Curated YouTube trading strategy videos |
| 2 | `StocksView` | Top stock recommendations from API |
| 3 | `AiBotView` | AI chat (Trading Insights + Chart Insights tabs) |
| 4 | `BrokersView` | Broker partner cards + "How to Claim Benefits" |
| 5 | `SubscriptionView` | RevenueCat premium plan purchase |

**Auxiliary Screens:** `AuthWrapper`, `LoginView`, `SignupView`, `MainNavigationScreen` (with Drawer), `SettingsView`, `VideoPlayerScreen`

### Drawer Contents
- Profile header (name, phone, premium badge)
- Settings link
- Support link
- Logout

### Settings Options
- Theme switching (Light / Dark / System)
- Language switching (English / Hindi)
- Push notification toggle (placeholder)
- Profile info display
- Premium status with upgrade button
- Help & Support (privacy policy link)
- App version display
- Logout with confirmation

---

## 6. Main Server (Backend API)

### File Tree
```
stock_archery/server/
├── server.js                                    # Express 5 app, mounts routes, starts server
├── package.json                                 # Dependencies
├── .env                                         # Secrets (MONGO_URI, OPENAI_API_KEY, TWOFACTOR_API_KEY)
├── firebase-service-account.json                # Firebase Admin credentials (gitignored)
│
├── config/
│   ├── db.js                                    # mongoose.connect(MONGO_URI), fatal on failure
│   └── firebase.js                              # Firebase Admin SDK init, graceful fallback
│
├── middleware/
│   └── auth.js                                  # requireAuth: Bearer token → Firebase verify or mock fallback
│
├── models/
│   ├── User.js                                  # users collection schema
│   ├── Recommendation.js                        # recommendations collection schema
│   └── UserAlertAccess.js                       # user_alert_access collection schema
│
├── routes/
│   ├── authRoutes.js                            # /api/auth/*
│   ├── userRoutes.js                            # /api/user/*
│   ├── chatRoutes.js                            # /api/chat, /api/chart-analysis
│   ├── recommendationRoutes.js                  # /api/recommendations
│   └── notificationRoutes.js                    # /api/test/push, /api/admin/push/broadcast
│
└── controllers/
    ├── authController.js                        # sendOtp (2Factor.in), syncUser (MongoDB upsert)
    ├── userController.js                        # registerDevice, unregisterDevice, updateAlertAccess
    ├── chatController.js                        # OpenAI GPT-4o chat + chart analysis
    ├── recommendationController.js              # getRecommendations from MongoDB
    └── notificationController.js                # FCM push (targeted + broadcast)
```

### Server Startup Flow
1. Load `.env` via dotenv
2. Connect to MongoDB Atlas via `config/db.js`
3. Initialize Firebase Admin SDK via `config/firebase.js` (graceful fallback if missing)
4. Mount all route files on Express 5 app
5. Listen on `PORT` (default 5000)

### OpenAI Integration Details
- **Model:** GPT-4o via OpenAI Responses API (`/v1/responses`)
- **Chat:** Includes `web_search_preview` tool for real-time market data
- **Chart Analysis:** Accepts base64 images, analyzes with vision capabilities
- **System Prompt:** "Stock Archery AI" — finance/markets expert persona
- **Parameters:** temperature=0.4, top_p=0.9, max_tokens=1000 (chat) / 1500 (chart)
- **Retry Logic:** Auto-retries once on "broken tool continuation" (web search completed but no message)

### OTP Flow
1. Client sends `POST /api/auth/send-otp` with `phoneNumber`
2. Server calls 2Factor.in API with `AUTOGEN2` template
3. OTP is returned in response (development concern — should be SMS-only)
4. Client completes Firebase phone auth

---

## 7. Admin Client (Flutter Dashboard)

### File Tree
```
admin/client/admin/lib/
├── main.dart                                    # Entry point, Provider setup, dark theme
├── models/
│   └── stock_recommendation.dart                # StockRecommendation: id, stocks, updatedAt
├── services/
│   └── mongodb_service.dart                     # Direct MongoDB connection + HTTP to admin server
├── viewmodels/
│   └── stock_viewmodel.dart                     # StockViewModel: selection logic, save, refresh
└── views/
    ├── home_page.dart                           # Dashboard landing page
    └── stock_selection_page.dart                # Stock picker with search, 5-slot selection tray
```

**Total:** 7 Dart files. Uses **Provider** (not Riverpod) for MVVM.

### Core Functionality
1. **Fetch F&O Stocks:** Direct MongoDB read from `fnostocks` collection
2. **Select 5 Stocks:** UI with search filter, max 5 selection cap
3. **Publish Recommendations:** Upserts to `recommendations` collection
4. **Refresh from Upstox:** Triggers admin server `POST /refresh-fno`

### Business Rule
Admin **must** select exactly 5 stocks. Fewer or more will not allow saving.

### Data Flow
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
Main Client (end-user app)
```

---

## 8. Admin Server (F&O Data Service)

### File Tree
```
admin/server/
├── index.js                                     # Express server (ESM), 122 lines
├── .env                                         # mongoUri
├── package.json                                 # type: "module"
└── node_modules/
```

### Endpoints

| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/` | Health check |
| GET | `/fno-stocks` | Returns cached F&O stock list from memory/MongoDB |
| POST | `/refresh-fno` | Fetches from Upstox, decompresses gzip, stores in MongoDB |

### Data Fetch Flow
1. Fetch `https://assets.upstox.com/market-quote/instruments/exchange/NSE.json.gz`
2. Decompress via `zlib.gunzipSync()`
3. Parse JSON, filter `segment === "NSE_FO"`
4. Extract unique `underlying_symbol` values
5. Wipe `fnostocks` collection, repopulate with sorted list
6. Update in-memory cache

### MongoDB Schema (Admin)
**Collection:** `fnostocks`
| Field | Type |
|-------|------|
| symbol | String (unique index) |
| updatedAt | Date |

---

## 9. Database Schema

### Collection: `users`
| Field | Type | Constraints |
|-------|------|-------------|
| firebaseUid | String | required, unique, indexed |
| name | String | required, trimmed |
| email | String | required, unique, lowercase, trimmed |
| phoneNumber | String | required, trimmed |
| location | String | required, trimmed |
| isPremium | Boolean | default: false |
| premiumExpiresAt | Date | default: null |
| fcmTokens | Array of subdocuments | (see below) |
| createdAt | Date | auto (timestamps) |
| updatedAt | Date | auto (timestamps) |

**`fcmTokens` subdocument:**
| Field | Type | Default |
|-------|------|---------|
| token | String | required |
| deviceId | String | required |
| platform | String | — |
| isActive | Boolean | true |
| updatedAt | Date | Date.now |

### Collection: `recommendations`
| Field | Type |
|-------|------|
| type | String (e.g., "current_recommendations") |
| stocks | Array of Strings |
| updatedAt | String |

### Collection: `user_alert_access`
| Field | Type | Default |
|-------|------|---------|
| firebaseUid | String | required, unique, indexed |
| isSOB_alert_premium | Boolean | false |
| SOB_alert_expiresAt | Date | null |
| isXaud_alert_premium | Boolean | false |
| Xaud_alert_expiresAt | Date | null |
| isCrypto_alert_premium | Boolean | false |
| Crypto_alert_expiresAt | Date | null |
| createdAt | Date | auto |
| updatedAt | Date | auto |

### Collection: `fnostocks` (Admin)
| Field | Type |
|-------|------|
| symbol | String (unique index) |
| updatedAt | Date |

---

## 10. API Endpoints

### Main Server

| Method | Endpoint | Auth | Rate Limit | Description |
|--------|----------|------|------------|-------------|
| GET | `/` | No | No | Health check |
| POST | `/api/auth/send-otp` | No | No | Send 6-digit OTP via 2Factor.in |
| POST | `/api/auth/sync` | Yes | No | Create/update user in MongoDB |
| POST | `/api/user/device/register` | Yes | No | Register FCM device token |
| POST | `/api/user/device/unregister` | Yes | No | Deactivate FCM device token |
| PUT | `/api/user/alert-access/:firebaseUid` | **No** | No | Update alert premium access flags |
| GET | `/api/recommendations` | No | No | Get current 5 recommended stocks |
| POST | `/api/chat` | No | No | AI trading chat (GPT-4o + web search) |
| POST | `/api/chart-analysis` | No | No | AI chart image analysis (GPT-4o vision) |
| POST | `/api/test/push` | Yes | No | Test push to user's devices |
| POST | `/api/admin/push/broadcast` | Yes* | No | Broadcast to `all_users` FCM topic |

### Admin Server

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Health check |
| GET | `/fno-stocks` | Get cached F&O stock list |
| POST | `/refresh-fno` | Trigger Upstox data refresh |

---

## 11. Authentication Flow

```
User opens app
    ↓
AuthWrapper checks Firebase state
    ↓
If not logged in → LoginView
    ↓
User enters email/password
    ↓
Firebase Auth signInWithEmailAndPassword
    ↓
If Firebase unavailable → mock mode (generates synthetic UID)
    ↓
authProvider fires syncUser → POST /api/auth/sync
    ↓
Server upserts User + UserAlertAccess in MongoDB
    ↓
sessionProvider starts RTDB listener on active_sessions/{uid}
    ↓
MainNavigationScreen loads (5 tabs + drawer)
```

### Phone OTP Flow (Signup)
```
Step 1: Name + Phone → POST /api/auth/send-otp → 2Factor.in SMS
Step 2: User enters 6-digit OTP → Firebase phone auth verification
Step 3: Email + Location + Password → Firebase createUserWithEmailAndPassword
Step 4: Sync to MongoDB
```

### Single-Device Login Enforcement
1. On login, write `{ sessionId, timestamp }` to Firebase RTDB at `active_sessions/{uid}`
2. Store `sessionId` in SharedPreferences
3. Real-time listener monitors `active_sessions/{uid}`
4. If `sessionId` changes (another device logged in), trigger force-logout
5. Force-logout clears local state and redirects to LoginView

### Dev/Mock Fallback
When `Firebase.apps.isEmpty` (no Firebase config):
- Generates synthetic UIDs (`mock-uid-{random}`)
- Skips Firebase Auth, directly calls backend sync
- `middleware/auth.js` accepts `mock-uid-*` tokens without verification

---

## 12. State Management (Riverpod Providers)

| Provider | Type | File | State Class | Purpose |
|----------|------|------|-------------|---------|
| `authServiceProvider` | `Provider<AuthService>` | `auth_viewmodel.dart` | — | AuthService singleton |
| `authProvider` | `StateNotifierProvider<AuthViewModel, AuthState>` | `auth_viewmodel.dart` | `AuthState` | User object, loading, errors, kick-out |
| `sessionServiceProvider` | `Provider<SessionService>` | `session_provider.dart` | — | SessionService singleton |
| `sessionProvider` | `Provider<void>` | `session_provider.dart` | — | Side-effect: starts/stops RTDB listener |
| `navigationProvider` | `StateProvider<int>` | `navigation_viewmodel.dart` | `int` | Bottom nav tab index |
| `settingsProvider` | `StateNotifierProvider<SettingsViewModel, SettingsState>` | `settings_viewmodel.dart` | `SettingsState` | Theme mode + language |
| `stocksServiceProvider` | `Provider<StocksService>` | `stocks_viewmodel.dart` | — | StocksService singleton |
| `recommendationsProvider` | `FutureProvider<List<String>>` | `stocks_viewmodel.dart` | `List<String>` | Async stock recommendations |
| `videoProvider` | `Provider<List<VideoModel>>` | `video_viewmodel.dart` | `List<VideoModel>` | Static video list |
| `chatProvider` | `StateNotifierProvider<ChatViewModel, ChatState>` | `chat_viewmodel.dart` | `ChatState` | Text-based AI chat |
| `chartProvider` | `StateNotifierProvider<ChatViewModel, ChatState>` | `chat_viewmodel.dart` | `ChatState` | Chart-based AI chat |
| `premiumProvider` | `StateNotifierProvider<PremiumNotifier, PremiumState>` | `premium_provider.dart` | `PremiumState` | RevenueCat entitlement + purchase |
| `offeringsProvider` | `FutureProvider<Offerings?>` | `offering_provider.dart` | `Offerings?` | Async RevenueCat offerings |

### State Patterns Used
- **StateNotifier + StateNotifierProvider:** Complex mutable state (auth, settings, chat, premium)
- **StateProvider:** Simple primitives (navigation index)
- **FutureProvider:** Async one-shot data (recommendations, offerings)
- **Provider:** Service singletons and static data

### Widget Participation
All screens extend `ConsumerWidget` or `ConsumerStatefulWidget` to watch/read providers.

---

## 13. Key Business Logic

### Stock Recommendations
1. Admin fetches F&O stocks from Upstox via admin server
2. Admin selects exactly 5 stocks in admin client
3. Admin saves → upserts to MongoDB `recommendations` collection
4. Main client fetches via `GET /api/recommendations`
5. Displayed in `StocksView` as numbered recommendation cards

### AI Chat (Trading Insights)
1. User sends text message
2. Client sends `POST /api/chat` with `{ message }`
3. Server calls OpenAI GPT-4o Responses API with `web_search_preview` tool
4. Response parsed for text, citations, web search status
5. If "broken tool continuation" detected, auto-retries once
6. Response rendered with Markdown in chat UI

### AI Chart Analysis
1. User takes/selects image of a stock chart
2. Image converted to base64
3. Client sends `POST /api/chart-analysis` with `{ message, image }`
4. Server calls GPT-4o vision with the image + text
5. Financial disclaimer appended to response
6. Rendered in `Chart Insights` chat tab

### Premium Subscription
1. `offeringsProvider` fetches offerings from RevenueCat on app start
2. `SubscriptionView` displays annual plan card
3. User taps purchase → bottom sheet confirmation
4. `premiumProvider` calls RevenueCat `purchasePackage()`
5. On success, `isPremium` state updates, gated content unlocks

### Push Notifications
- **Registration:** On login, FCM token sent to `POST /api/user/device/register`
- **Targeted:** Server uses `sendEachForMulticast` to specific device tokens
- **Broadcast:** `POST /api/admin/push/broadcast` sends to `all_users` FCM topic
- **Cleanup:** Invalid/expired tokens auto-deactivated

### Session Enforcement
1. Login writes `{ sessionId, timestamp }` to RTDB `active_sessions/{uid}`
2. Real-time listener monitors path
3. On change: compare local sessionId with DB sessionId
4. Mismatch → force-logout (clear providers, navigate to login)

---

## 14. Security Concerns

| # | Issue | Severity | Location | Recommendation |
|---|-------|----------|----------|----------------|
| 1 | **Unprotected alert-access endpoint** — anyone can grant/revoke premium for any user | **HIGH** | `userRoutes.js:8` — `PUT /api/user/alert-access/:firebaseUid` has no auth middleware | Add `requireAuth` + admin role check |
| 2 | **No admin check on broadcast** — any authenticated user can push to all users | **MEDIUM** | `notificationController.js:74` | Add admin role verification |
| 3 | **Unprotected AI endpoints** — no auth or rate limiting, anyone can consume OpenAI credits | **MEDIUM** | `chatRoutes.js` | Add auth + rate limiting |
| 4 | **OTP returned in API response** — should only be sent via SMS | **MEDIUM** | `authController.js:24` | Remove OTP from response body |
| 5 | **Admin client connects directly to MongoDB** — credentials embedded in Flutter client | **MEDIUM** | `mongodb_service.dart` | Route all writes through admin server API |
| 6 | **No rate limiting anywhere** — vulnerable to abuse | **MEDIUM** | All routes | Add `express-rate-limit` |
| 7 | **No input validation/sanitization** — relies on manual checks | **MEDIUM** | All controllers | Add `joi` or `zod` validation |
| 8 | **Mock auth fallback** accepts any `mock-uid-*` | **LOW** | `middleware/auth.js:18` | Only in dev mode, acceptable |
| 9 | **Live secrets in .env committed to git history** | **LOW** | `.env` files | Rotate keys, use git-secrets |

---

## 15. Environment Variables

### Main Client (`stock_archery/client/.env`)
```
APP_ENV=development|production
DEV_BASE_URL=http://localhost:5000
PROD_BASE_URL=https://your-main-url.onrender.com
```

### Main Server (`stock_archery/server/.env`)
```
PORT=5000
MONGO_URI=mongodb+srv://...
OPENAI_API_KEY=sk-proj-...
TWOFACTOR_API_KEY=e6ec9604-...
# GEMINI_API_KEY=AIzaSy... (unused, commented out)
```

### Admin Client (`admin/client/admin/.env`)
```
SERVER_URL=https://stock-archery.onrender.com
mongoUri=mongodb+srv://...
```

### Admin Server (`admin/server/.env`)
```
mongoUri=mongodb+srv://...
```

---

## 16. Deployment

| Component | Platform | URL |
|-----------|----------|-----|
| Main Server | Render.com | `https://stock-archery.onrender.com` |
| Admin Server | Render.com | `https://your-admin-url.onrender.com` |
| Main Client | Flutter build (Android/iOS/Web) | — |
| Admin Client | Flutter build (Desktop/Web) | — |
| Database | MongoDB Atlas | `cluster0.d4gsz5f.mongodb.net` |
| Auth | Firebase Authentication | — |
| Push | Firebase Cloud Messaging | — |
| Subscriptions | RevenueCat | — |
| OTP | 2Factor.in | — |
| AI | OpenAI API | — |

### Build Commands
```bash
# Main Client
flutter pub get
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web

# Main Server
cd stock_archery/server
npm install
npm start                  # node server.js

# Admin Server
cd admin/server
npm install
npm start                  # node index.js

# Admin Client
cd admin/client/admin
flutter pub get
flutter run                # or flutter build
```

---

## Quick Reference for AI Agents

When working on this codebase, keep these facts in mind:

1. **Architecture:** MVVM pattern throughout. Main client uses Riverpod; admin client uses Provider.
2. **Two separate Flutter apps** — main client (`stock_archery/client/`) and admin client (`admin/client/admin/`). They share no code.
3. **Two separate Node.js servers** — main server (`stock_archery/server/`) for end-user API; admin server (`admin/server/`) for F&O data fetching.
4. **Single MongoDB Atlas cluster** shared by all components (`stock_archery` database).
5. **Firebase is optional in dev** — both client and server have graceful mock fallbacks when Firebase credentials are missing.
6. **Express 5** (not 4) is used — note async error handling differences.
7. **RevenueCat** handles premium subscriptions, not the backend.
8. **OpenAI GPT-4o** is the AI model, using the newer Responses API (not Chat Completions).
9. **The design system is "Aureum Elite"** — dark theme with gold accents. All custom tokens are in `utils/design_system/`.
10. **No test suite exists** — both servers have `"test": "echo \"Error: no test specified\" && exit 1"` in package.json.
