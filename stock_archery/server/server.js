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

// Initialization
initFirebase();
connectDB();

const PORT = process.env.PORT || 5000;

// Health check
app.get('/', (req, res) => {
  res.json({ status: "ok", message: "Stock Archery Main Server" });
});

// Mount routers
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api', chatRoutes); // /api/chat and /api/chart-analysis
app.use('/api', notificationRoutes); // /api/test/push and /api/admin/push/broadcast
app.use('/api/alerts', alertRoutes);

app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});