# Alert Feed Feature — Implementation Plan

> **Created:** July 2026
> **Status:** Ready for Implementation
> **Feature:** Admin sends chart image + text alerts for SOB / XAUD / Crypto categories; users view them in a new Alerts tab

---

## Table of Contents

1. [Feature Overview](#1-feature-overview)
2. [Architecture](#2-architecture)
3. [Design Decisions](#3-design-decisions)
4. [MongoDB Schema](#4-mongodb-schema)
5. [API Endpoints](#5-api-endpoints)
6. [File Manifest](#6-file-manifest)
7. [UI Design](#7-ui-design)
8. [Implementation Phases](#8-implementation-phases)
9. [Key Technical Details](#9-key-technical-details)
10. [Premium Gating Logic](#10-premium-gating-logic)

---

## 1. Feature Overview

**What:** Admin can send alert posts (chart image + text message) to 3 categories: SOB, Crypto, XAUD. All users see these posts in a new "Alerts" tab in the main app, gated by their alert premium status.

**Why:** Gives admins a way to push curated chart analysis and market alerts to premium users in a feed-style interface.

**User flow:**
1. Admin opens admin app → taps "Send Alert" → selects category → picks chart image → types message → sends
2. Main app user opens Alerts tab → selects category → sees feed of posts (if premium) or locked state (if not)

---

## 2. Architecture

```
┌──────────────────┐   POST/GET/DELETE    ┌──────────────────┐    ┌────────────┐
│  Admin Client     │ ──────────────────▶ │  Admin Server     │───▶│  MongoDB   │
│  (Flutter)        │   HTTP + JSON       │  (Node.js/Express)│    │  alert_    │
│                   │                     │  NEW endpoints     │    │  posts     │
└──────────────────┘                     └──────────────────┘    └─────┬──────┘
                                                                       │
┌──────────────────┐   GET /api/alerts/:cat ┌──────────────────┐      │
│  Main Client      │ ◄─────────────────── │  Main Server      │──────┘
│  (Flutter)        │   HTTP + JSON        │  (Node.js/Express)│  reads
│                   │                      │  NEW endpoint      │
└──────────────────┘                      └──────────────────┘
```

**Key principle:** No frontend (admin or main) calls MongoDB directly for this feature. All database operations go through the respective Node.js servers.

- **Admin Server** owns writes (create, delete) and reads for the admin client
- **Main Server** owns reads for the end-user main client
- Both servers connect to the same MongoDB Atlas cluster (`stock_archery` database)

Existing direct-MongoDB operations in the admin client (stocks, recommendations) remain unchanged.

---

## 3. Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| **Alert access gating** | Yes, gated by premium | `isSOBAlertPremium`, `isXaudAlertPremium`, `isCryptoAlertPremium` on UserModel |
| **Image storage** | Base64 in MongoDB | Matches existing chart-analysis pattern, no extra services, preserves chart quality |
| **Post deletion** | Admin can delete | Long-press or trash icon on each post in history |
| **Feed ordering** | Oldest first (chat style) | Scroll down for newer posts, like a chat history |
| **UI components** | Custom-built | `dash_chat_2` is for two-way chat; alerts are one-way feed with full-width images |
| **Image quality** | No compression | Charts need high resolution; base64 preserves original quality |

---

## 4. MongoDB Schema

### Collection: `alert_posts`

| Field | Type | Constraints | Default |
|---|---|---|---|
| `_id` | ObjectId | auto | auto |
| `category` | String | required, enum: `['SOB', 'XAUD', 'Crypto']` | — |
| `text` | String | required | — |
| `imageBase64` | String | required | — |
| `createdAt` | Date | auto | timestamps |
| `updatedAt` | Date | auto | timestamps |

---

## 5. API Endpoints

### Admin Server (new)

| Method | Route | Body | Response | Description |
|---|---|---|---|---|
| POST | `/alerts` | `{ category, text, imageBase64 }` | `{ status, alert }` | Create new alert post |
| GET | `/alerts/:category` | — | `{ status, alerts: [...] }` | Get posts for category (oldest first) |
| DELETE | `/alerts/:id` | — | `{ status, message }` | Delete alert post by _id |

### Main Server (new)

| Method | Route | Auth | Response | Description |
|---|---|---|---|---|
| GET | `/api/alerts/:category` | No | `[{ _id, category, text, imageBase64, createdAt }]` | Get posts for category (oldest first) |

---

## 6. File Manifest

### Phase 1: Admin Server (3 new, 1 modified)

| # | File | Action |
|---|---|---|
| 1 | `admin/server/models/AlertPost.js` | Create |
| 2 | `admin/server/controllers/alertController.js` | Create |
| 3 | `admin/server/routes/alertRoutes.js` | Create |
| 4 | `admin/server/index.js` | Modify — mount routes |

### Phase 2: Main Server (3 new, 1 modified)

| # | File | Action |
|---|---|---|
| 5 | `stock_archery/server/models/AlertPost.js` | Create |
| 6 | `stock_archery/server/controllers/alertController.js` | Create |
| 7 | `stock_archery/server/routes/alertRoutes.js` | Create |
| 8 | `stock_archery/server/server.js` | Modify — mount routes |

### Phase 3: Admin Client (4 new, 3 modified)

| # | File | Action |
|---|---|---|
| 9 | `admin/client/admin/models/alert_post.dart` | Create |
| 10 | `admin/client/admin/pubspec.yaml` | Modify — add image_picker |
| 11 | `admin/client/admin/services/admin_api_service.dart` | Create |
| 12 | `admin/client/admin/viewmodels/alert_viewmodel.dart` | Create |
| 13 | `admin/client/admin/views/alert_send_page.dart` | Create |
| 14 | `admin/client/admin/views/home_page.dart` | Modify — add action tile |
| 15 | `admin/client/admin/main.dart` | Modify — register provider |

### Phase 4: Main Client (4 new, 1 modified)

| # | File | Action |
|---|---|---|
| 16 | `stock_archery/client/lib/models/alert_post.dart` | Create |
| 17 | `stock_archery/client/lib/services/alerts_service.dart` | Create |
| 18 | `stock_archery/client/lib/viewmodels/alerts_provider.dart` | Create |
| 19 | `stock_archery/client/lib/views/alerts_view.dart` | Create |
| 20 | `stock_archery/client/lib/views/main_navigation_screen.dart` | Modify — add 5th tab |

**Total: 14 new files, 6 modified files**

---

## 7. UI Design

### Main Client — Alerts Tab

```
┌──────────────────────────────┐
│  AppBar: "Alerts"            │
├──────────────────────────────┤
│  [SOB]  [XAUD]  [Crypto]    │  ← 3 segment buttons
├──────────────────────────────┤
│                              │
│  ┌────────────────────────┐  │
│  │  📊 Chart Image        │  │  ← Full-width, high quality
│  │  (tap to zoom)         │  │
│  ├────────────────────────┤  │
│  │  Analysis text here... │  │
│  │  Jul 5, 2026 2:30 PM   │  │  ← Timestamp
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │  📊 Chart Image        │  │
│  │  ...                   │  │
│  └────────────────────────┘  │
│                              │
│  (scrolls down for older)    │
└──────────────────────────────┘
```

**Locked state** (user lacks premium for that category):
```
┌──────────────────────────────┐
│         🔒                   │
│  Unlock {Category} Alerts    │
│  Contact support to get      │
│  premium access              │
└──────────────────────────────┘
```

### Admin Client — Alert Send Page

```
┌──────────────────────────────┐
│  ← Send Alert                │
├──────────────────────────────┤
│  Select Category:            │
│  [SOB]  [XAUD]  [Crypto]    │  ← Toggle buttons
├──────────────────────────────┤
│                              │
│  ┌────────────────────────┐  │
│  │   📷 Tap to add image  │  │  ← Image picker area
│  │   (or selected image)  │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │  Type your message...  │  │  ← TextField (multiline)
│  └────────────────────────┘  │
│                              │
│  [  Send Alert  ]            │  ← Gold CTA button
│                              │
├──────────────────────────────┤
│  Previous Posts (3):         │  ← History with delete
│  ┌────────────────────────┐  │
│  │ Chart + text  [Delete] │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ Chart + text  [Delete] │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

### Feed Item Card (Main Client)

```dart
Container(
  margin: EdgeInsets.only(bottom: AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.pureBlack,
    borderRadius: BorderRadius.circular(AppRadii.base),
    border: Border.all(color: AppColors.goldBright.withOpacity(0.15)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Full-width chart image
      ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.base)),
        child: Image.memory(
          base64Decode(post.imageBase64),
          fit: BoxFit.fitWidth,
          width: double.infinity,
        ),
      ),
      // Text + timestamp
      Padding(
        padding: EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.text, style: AppTypography.bodyLg()),
            SizedBox(height: AppSpacing.sm),
            Text formattedTimestamp,  // AppTypography.labelSm, subtleGrey
          ],
        ),
      ),
    ],
  ),
)
```

---

## 8. Implementation Phases

### Phase 1: Admin Server — API Layer

**Step 1:** Create `admin/server/models/AlertPost.js`
```js
const mongoose = require('mongoose');
const alertPostSchema = new mongoose.Schema({
  category: { type: String, required: true, enum: ['SOB', 'XAUD', 'Crypto'] },
  text: { type: String, required: true },
  imageBase64: { type: String, required: true },
}, { timestamps: true, collection: 'alert_posts' });
module.exports = mongoose.model('AlertPost', alertPostSchema);
```

**Step 2:** Create `admin/server/controllers/alertController.js`
- `createAlert` — validates category/text/imageBase64, inserts document
- `getAlertsByCategory` — finds by category, sorts `{ createdAt: 1 }` (ascending)
- `deleteAlert` — deletes by `_id`, returns success/failure

**Step 3:** Create `admin/server/routes/alertRoutes.js`
```js
router.post('/', alertController.createAlert);
router.get('/:category', alertController.getAlertsByCategory);
router.delete('/:id', alertController.deleteAlert);
```

**Step 4:** Modify `admin/server/index.js`
- Import routes
- `app.use('/alerts', alertRoutes)`

### Phase 2: Main Server — Read API

**Step 5:** Create `stock_archery/server/models/AlertPost.js` (same schema)

**Step 6:** Create `stock_archery/server/controllers/alertController.js`
- `getAlertsByCategory` — finds by category, sorts `{ createdAt: 1 }`

**Step 7:** Create `stock_archery/server/routes/alertRoutes.js`
```js
router.get('/:category', alertController.getAlertsByCategory);
```

**Step 8:** Modify `stock_archery/server/server.js`
- `app.use('/api/alerts', alertRoutes)`

### Phase 3: Admin Client — Send UI

**Step 9:** Create `admin/client/admin/models/alert_post.dart`
```dart
class AlertPost {
  final String id;
  final String category;
  final String text;
  final String imageBase64;
  final DateTime createdAt;
  // fromJson, toJson
}
```

**Step 10:** Modify `admin/client/admin/pubspec.yaml`
- Add `image_picker: ^1.1.2` to dependencies

**Step 11:** Create `admin/client/admin/services/admin_api_service.dart`
- Singleton HTTP service
- `baseUrl` from dotenv `SERVER_URL`
- `createAlert(category, text, imageBase64)` → POST `/alerts`
- `getAlerts(category)` → GET `/alerts/:category`
- `deleteAlert(id)` → DELETE `/alerts/:id`

**Step 12:** Create `admin/client/admin/viewmodels/alert_viewmodel.dart`
- State: `selectedCategory`, `pickedImage`, `message`, `isSending`, `alerts`
- Actions: `pickImage()`, `sendAlert()`, `loadAlerts()`, `deleteAlert(id)`
- `sendAlert()` validates fields → base64 encodes image → calls API → refreshes list

**Step 13:** Create `admin/client/admin/views/alert_send_page.dart`
- Category toggle buttons
- Image picker area (tap to select, preview selected image)
- Multiline text input
- Send button with loading state
- Previous posts list with delete buttons

**Step 14:** Modify `admin/client/admin/views/home_page.dart`
- Add second gradient action tile: "Send Alert" → navigates to AlertSendPage

**Step 15:** Modify `admin/client/admin/main.dart`
- Add `ChangeNotifierProvider(create: (_) => AlertViewModel())` to MultiProvider

### Phase 4: Main Client — Display UI

**Step 16:** Create `stock_archery/client/lib/models/alert_post.dart`
```dart
class AlertPost {
  final String id;
  final String category;
  final String text;
  final String imageBase64;
  final DateTime createdAt;
  // fromJson
}
```

**Step 17:** Create `stock_archery/client/lib/services/alerts_service.dart`
- `getAlerts(category)` → GET `/api/alerts/:category`
- Returns `List<AlertPost>`

**Step 18:** Create `stock_archery/client/lib/viewmodels/alerts_provider.dart`
```dart
final alertsServiceProvider = Provider<AlertsService>((ref) {
  return AlertsService(baseUrl: AppConfig.baseUrl);
});

final alertsProvider = FutureProvider.family<List<AlertPost>, String>((ref, category) async {
  final service = ref.watch(alertsServiceProvider);
  return service.getAlerts(category);
});
```

**Step 19:** Create `stock_archery/client/lib/views/alerts_view.dart`
- `ConsumerWidget` scaffold with `AppColors.deepObsidian` background
- State: `_selectedCategory` (default: 'SOB')
- AppBar: "Alerts" title
- 3 segment buttons below AppBar
- Body: checks premium → feed or locked state
- Feed: `ListView.builder` with `AlertPostCard` widgets
- Each card: `Image.memory(base64Decode(...))` + text + timestamp
- `RefreshIndicator` for pull-to-refresh
- Empty state when no posts

**Step 20:** Modify `stock_archery/client/lib/views/main_navigation_screen.dart`
- Import `AlertsView`
- Insert `const AlertsView()` at index 4 in `screens` list
- Add `BottomNavigationBarItem(icon: Icon(Icons.notifications_active_outlined), label: 'Alerts')`
- Shift Premium tab to index 5

---

## 9. Key Technical Details

### Image Handling

**Admin client (upload):**
```dart
// Pick image
final picker = ImagePicker();
final XFile? image = await picker.pickImage(
  source: ImageSource.gallery,
  imageQuality: 100,  // No compression — preserve chart quality
);

// Convert to base64
final bytes = await File(image!.path).readAsBytes();
final base64Image = base64Encode(bytes);

// Send to server
await adminApiService.createAlert(category, text, base64Image);
```

**Main client (display):**
```dart
// Decode and display
Image.memory(
  base64Decode(post.imageBase64),
  fit: BoxFit.fitWidth,
  width: double.infinity,
)
```

**Why base64:** Matches the existing pattern used by `POST /api/chart-analysis` which already accepts base64 images. MongoDB document limit is 16MB — a typical chart image is 500KB-2MB as base64, well within limits.

### Timestamp Formatting
```dart
String _formatTimestamp(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return DateFormat('MMM d, yyyy • h:mm a').format(date);
}
```

### Admin Delete Flow
```dart
// Long-press or trash icon on each post
onTap: () async {
  final confirm = await showDialog<bool>(...);
  if (confirm == true) {
    await viewModel.deleteAlert(post.id);
    // List refreshes automatically
  }
}
```

---

## 10. Premium Gating Logic

### Main Client — Access Check

```dart
final user = ref.watch(authProvider).user;

bool _isCategoryLocked(String category) {
  return switch (category) {
    'SOB' => user?.isSOBAlertPremium != true,
    'XAUD' => user?.isXaudAlertPremium != true,
    'Crypto' => user?.isCryptoAlertPremium != true,
    _ => true,
  };
}
```

### How Premium Flags Are Set

Via the existing unauthenticated endpoint:
```
PUT /api/user/alert-access/:firebaseUid
Body: { "isSOB_alert_premium": true }
```

Sets flag to `true` + 1-year expiry from now. Admin or backend system calls this to grant access.

### Auto-Expiry

On every `POST /api/auth/sync` (login), the server checks:
```js
if (alertAccess.isSOB_alert_premium && alertAccess.SOB_alert_expiresAt < now) {
  alertAccess.isSOB_alert_premium = false;
  await alertAccess.save();
}
```

Same for Xaud and Crypto. Expired flags are automatically cleared.

---

## Summary

| Metric | Count |
|---|---|
| New files | 14 |
| Modified files | 6 |
| New MongoDB collections | 1 (`alert_posts`) |
| New API endpoints | 4 (3 admin server + 1 main server) |
| New Flutter views | 2 (`alerts_view.dart`, `alert_send_page.dart`) |
| New viewmodels | 2 (`alert_viewmodel.dart`, `alerts_provider.dart`) |
| New services | 2 (`admin_api_service.dart`, `alerts_service.dart`) |
| New models | 2 (`alert_post.dart` x2) |
