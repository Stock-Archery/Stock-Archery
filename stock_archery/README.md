# Stock Archery

## Project Structure
- `/client`: Flutter Application
- `/server`: Node.js Express Backend

## Backend Architecture
The backend is built with Node.js and Express, connected to MongoDB and Firebase.

### Folder Structure
- **config/**: Stores database and firebase initialization logic.
- **models/**: Mongoose schemas (e.g., `User`, `Recommendation`).
- **middleware/**: Express middleware functions, such as `requireAuth` for verifying Firebase tokens.
- **controllers/**: Contains all core business logic (Auth, User Devices, Recommendations, Chat/AI, Notifications).
- **routes/**: API route declarations that map endpoints to controllers.
- **server.js**: Application entry point that bootstraps Express, connects DBs, and mounts routes.

### Starting the Server
```bash
cd server
npm run start
```
