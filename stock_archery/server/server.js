const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');

// Load env
dotenv.config();

// Connect Database & Firebase
const connectDB = require('./config/db');
const { initFirebase } = require('./config/firebase');

// Route files
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const recommendationRoutes = require('./routes/recommendationRoutes');
const chatRoutes = require('./routes/chatRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const alertRoutes = require('./routes/alertRoutes');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[log] ──→ ${req.method} ${req.originalUrl}`);
  if (req.body && Object.keys(req.body).length > 0) {
    // Mask sensitive fields
    const masked = { ...req.body };
    if (masked.password) masked.password = '***';
    if (masked.phoneNumber) masked.phoneNumber = masked.phoneNumber;
    console.log(`[log] body: ${JSON.stringify(masked)}`);
  }
  next();
});

// Initialization
initFirebase();
connectDB();

const PORT = process.env.PORT || 5000;

// Health check
app.get('/', (req, res) => {
  res.json({ status: "ok", message: "Stock Archery Main Server", version: "1.0.1" });
});

// Mount routers
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api', chatRoutes); // /api/chat and /api/chart-analysis
app.use('/api', notificationRoutes); // /api/test/push and /api/admin/push/broadcast
app.use('/api/alerts', alertRoutes);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`[log] Server bound to 0.0.0.0:${PORT}`);
  console.log(`[log] MONGO_URI exists: ${!!process.env.MONGO_URI}`);
  console.log(`[log] OPENAI_API_KEY exists: ${!!process.env.OPENAI_API_KEY}`);
  console.log(`[log] TWOFACTOR_API_KEY exists: ${!!process.env.TWOFACTOR_API_KEY}`);
});