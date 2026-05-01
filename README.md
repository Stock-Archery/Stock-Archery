# Stock Archery API Documentation

This repository contains two backend services: the **Admin Server** and the **Main App Server**. Both are designed to be hosted on Render.

---

## 🛠 Admin Server
Responsible for managing the F&O stock list and providing data to the Admin Dashboard.

**Base URL:** `https://your-admin-url.onrender.com`

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/` | `GET` | Health check. |
| `/fno-stocks` | `GET` | Returns the list of all active F&O stocks (from cache or MongoDB). |
| `/refresh-fno` | `POST` | Triggers a fresh fetch from Upstox and updates the MongoDB collection. |

---

## 🚀 Main App Server
Responsible for serving recommendations and the AI Chat feature to the end-users.

**Base URL:** `https://your-main-url.onrender.com`

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/` | `GET` | Health check. |
| `/api/recommendations` | `GET` | Returns the current list of 5 recommended stocks. |
| `/api/chat` | `POST` | AI Chatbot endpoint. Expects `{"message": "string"}`. |

---

## 🔑 Environment Variables

### Admin Server
- `mongoUri`: MongoDB Atlas connection string.
- `PORT`: (Managed by Render)

### Main App Server
- `MONGO_URI`: MongoDB Atlas connection string.
- `OPENAI_API_KEY`: Your OpenAI API Key (Bearer Token).
- `PORT`: (Managed by Render)
