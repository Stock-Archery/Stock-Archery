const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const axios = require('axios');
const admin = require('firebase-admin');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

const PORT = process.env.PORT || 5000;

// Initialize Firebase Admin SDK safely
try {
  const serviceAccount = require('./firebase-service-account.json');
  if (serviceAccount.project_id && serviceAccount.project_id !== "YOUR_PROJECT_ID") {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log("✅ Firebase Admin SDK initialized successfully");
  } else {
    console.warn("⚠️ firebase-service-account.json contains placeholder values. Firebase verification will run in DEVELOPMENT fallback mode.");
  }
} catch (err) {
  console.warn("⚠️ Firebase Admin SDK could not load credentials. Running in DEVELOPMENT fallback mode.");
}

// Validate Environment Variables
if (!process.env.MONGO_URI) {
  console.error("FATAL ERROR: MONGO_URI is not defined.");
  process.exit(1);
}
if (!process.env.OPENAI_API_KEY) {
  console.error("FATAL ERROR: OPENAI_API_KEY is not defined.");
  process.exit(1);
}

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch(err => {
    console.error('❌ Could not connect to MongoDB', err);
    process.exit(1);
  });

// Define Schema for recommendations
const recommendationSchema = new mongoose.Schema({
  type: String,
  stocks: [String],
  updatedAt: String
}, { collection: 'recommendations' });

const Recommendation = mongoose.model('Recommendation', recommendationSchema);

// Define User Schema
const userSchema = new mongoose.Schema({
  firebaseUid: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  phoneNumber: {
    type: String,
    required: true,
    trim: true
  },
  location: {
    type: String,
    required: true,
    trim: true
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  premiumExpiresAt: {
    type: Date,
    default: null
  },
  fcmTokens: [{
    token: { type: String, required: true },
    deviceId: { type: String, required: true },
    platform: { type: String },
    isActive: { type: Boolean, default: true },
    updatedAt: { type: Date, default: Date.now }
  }]
}, {
  timestamps: true,
  collection: 'users'
});

const User = mongoose.model('User', userSchema);

// Authentication Middleware (Firebase verified token)
async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Authorization token missing' });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    if (admin.apps.length > 0) {
      const decodedToken = await admin.auth().verifyIdToken(token);
      req.user = decodedToken;
      next();
    } else {
      console.warn("⚠️ Firebase Admin not initialized. Falling back to development mock check.");
      if (token.startsWith("mock-uid-")) {
        const uid = token.replace("mock-uid-", "");
        req.user = { uid, email: `${uid}@mock.com` };
        return next();
      }
      return res.status(401).json({ message: 'Firebase Admin not configured. Please add firebase-service-account.json' });
    }
  } catch (err) {
    console.error("Token verification failed:", err);
    return res.status(401).json({ message: 'Invalid or expired authorization token', error: err.message });
  }
}

// Health check
app.get('/', (req, res) => {
  res.json({ status: "ok", message: "Stock Archery Main Server" });
});

// POST /api/auth/send-otp
// Generates and sends a 2factor SMS OTP for a phone number
app.post('/api/auth/send-otp', async (req, res) => {
  const { phoneNumber } = req.body;
  if (!phoneNumber) {
    return res.status(400).json({ message: 'Phone number is required' });
  }

  try {
    const apiKey = process.env.TWOFACTOR_API_KEY || "e6ec9604-5ea1-11f1-8352-0200cd936042";
    const url = `https://2factor.in/API/V1/${apiKey}/SMS/${phoneNumber}/AUTOGEN2/`;
    console.log(`📡 Requesting 2Factor OTP for ${phoneNumber}...`);
    const response = await axios.get(url);

    if (response.data && response.data.Status === "Success") {
      const otp = response.data.OTP;
      console.log(`🔑 Received 6-digit OTP from 2Factor for ${phoneNumber}: ${otp}`);
      res.json({
        success: true,
        message: 'OTP sent successfully via 2Factor',
        otp: otp
      });
    } else {
      console.error("❌ 2Factor API Error:", response.data);
      res.status(500).json({
        success: false,
        message: response.data ? response.data.Details : 'Failed to send OTP via 2factor'
      });
    }
  } catch (err) {
    console.error("❌ Failed to request OTP from 2Factor:", err.message);
    res.status(500).json({
      success: false,
      message: 'OTP service connection failed',
      error: err.message
    });
  }
});

// GET /api/recommendations
app.get('/api/recommendations', async (req, res) => {
  try {
    const data = await Recommendation.findOne({ type: 'current_recommendations' });
    if (data) {
      res.json(data.stocks);
    } else {
      res.status(404).json({ message: 'No recommendations found' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// POST /api/auth/sync
// Syncs authenticated Firebase user with MongoDB
app.post('/api/auth/sync', requireAuth, async (req, res) => {
  const { name, phoneNumber, location } = req.body;
  const { uid, email } = req.user;

  if (!email) {
    return res.status(400).json({ message: 'Email is required from auth credentials' });
  }

  try {
    // Find or create the user
    let user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      // If it's a new signup, validate that all required fields are present
      if (!name || !phoneNumber || !location) {
        return res.status(400).json({ message: 'Name, phone number, and location are required for new registration' });
      }

      user = new User({
        firebaseUid: uid,
        name,
        email,
        phoneNumber,
        location,
        isPremium: false
      });
      await user.save();
      console.log(`👤 New user registered and synced in MongoDB: ${email}`);
    } else {
      // If the user already exists, update their profile fields optionally if provided
      const updateData = {};
      if (name) updateData.name = name;
      if (phoneNumber) updateData.phoneNumber = phoneNumber;
      if (location) updateData.location = location;

      if (Object.keys(updateData).length > 0) {
        user = await User.findOneAndUpdate(
          { firebaseUid: uid },
          { $set: updateData },
          { new: true }
        );
      }
      console.log(`🔄 User logged in and synced: ${email}`);
    }

    res.json({
      status: "success",
      user: {
        firebaseUid: user.firebaseUid,
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        location: user.location,
        isPremium: user.isPremium,
        premiumExpiresAt: user.premiumExpiresAt
      }
    });
  } catch (err) {
    console.error('Error syncing user:', err);
    res.status(500).json({ message: 'User sync failed', error: err.message });
  }
});

// POST /api/user/device/register
// Registers or updates an FCM token for a device
app.post('/api/user/device/register', requireAuth, async (req, res) => {
  const { token, deviceId, platform } = req.body;
  const { uid } = req.user;

  if (!token || !deviceId) {
    return res.status(400).json({ message: 'Token and deviceId are required' });
  }

  try {
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const existingTokenIndex = user.fcmTokens.findIndex(t => t.deviceId === deviceId);

    if (existingTokenIndex > -1) {
      // Update existing device
      user.fcmTokens[existingTokenIndex].token = token;
      user.fcmTokens[existingTokenIndex].platform = platform || user.fcmTokens[existingTokenIndex].platform;
      user.fcmTokens[existingTokenIndex].isActive = true;
      user.fcmTokens[existingTokenIndex].updatedAt = new Date();
    } else {
      // Add new device
      user.fcmTokens.push({
        token,
        deviceId,
        platform,
        isActive: true,
        updatedAt: new Date()
      });
    }

    await user.save();
    // console.log(`✅ Device registered successfully: ${email}`);
    res.json({ status: 'success', message: 'Device registered successfully' });
  } catch (err) {

    console.error('Error registering device:', err);
    res.status(500).json({ message: 'Failed to register device', error: err.message });
  }
});

// POST /api/user/device/unregister
// Unregisters an FCM token (e.g., on logout)
app.post('/api/user/device/unregister', requireAuth, async (req, res) => {
  const { deviceId } = req.body;
  const { uid } = req.user;

  if (!deviceId) return res.status(400).json({ message: 'deviceId is required' });

  try {
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const existingTokenIndex = user.fcmTokens.findIndex(t => t.deviceId === deviceId);
    if (existingTokenIndex > -1) {
      user.fcmTokens[existingTokenIndex].isActive = false;
      user.fcmTokens[existingTokenIndex].updatedAt = new Date();
      await user.save();
    }

    res.json({ status: 'success', message: 'Device unregistered successfully' });
  } catch (err) {
    console.error('Error unregistering device:', err);
    res.status(500).json({ message: 'Failed to unregister device', error: err.message });
  }
});

// Helper Function: Send Push Notifications & Handle Inactive Tokens
async function sendPushNotification(user, title, body, data = {}) {
  const activeTokens = user.fcmTokens.filter(t => t.isActive).map(t => t.token);

  if (activeTokens.length === 0) {
    console.log(`No active tokens for user ${user.email}.`);
    return { successCount: 0, failureCount: 0 };
  }

  const message = {
    notification: { title, body },
    data,
    tokens: activeTokens
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    // Check for uninstalled/inactive tokens
    if (response.failureCount > 0) {
      const tokensToRemove = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            tokensToRemove.push(activeTokens[idx]);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        console.log(`Deactivating ${tokensToRemove.length} invalid tokens for user ${user.email}`);
        user.fcmTokens.forEach(t => {
          if (tokensToRemove.includes(t.token)) {
            t.isActive = false;
            t.updatedAt = new Date();
          }
        });
        await user.save();
      }
    }

    return response;
  } catch (err) {
    console.error('Push notification failed:', err);
    throw err;
  }
}

// POST /api/test/push (Testing utility)
app.post('/api/test/push', requireAuth, async (req, res) => {
  const { title, body } = req.body;
  const { uid } = req.user;

  try {
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const response = await sendPushNotification(user, title || 'Test Notification', body || 'This is a test');
    res.json({ status: 'success', response });
  } catch (err) {
    res.status(500).json({ message: 'Push test failed', error: err.message });
  }
});

// POST /api/admin/push/broadcast
// Sends a notification to ALL users subscribed to the 'all_users' topic
app.post('/api/admin/push/broadcast', requireAuth, async (req, res) => {
  const { title, body } = req.body;

  // NOTE: In production, you should add a check here to ensure req.user is an ADMIN

  const message = {
    notification: {
      title: title || 'Global Alert',
      body: body || 'This is a broadcast message to all users'
    },
    topic: 'all_users'
  };

  try {
    const response = await admin.messaging().send(message);
    res.json({ status: 'success', messageId: response });
  } catch (err) {
    console.error('Broadcast failed:', err);
    res.status(500).json({ message: 'Broadcast failed', error: err.message });
  }
});

// Helper to parse OpenAI Responses API timeline
function parseOpenAIResponse(apiResponse) {
  const output = apiResponse?.output || [];

  let reply = "";
  let citations = [];
  let usedWebSearch = false;
  let hasMessage = false;

  for (const item of output) {
    // Detect web search usage
    if (item.type === "web_search_call") {
      usedWebSearch = true;
      console.log("🔍 Tool Detected: web_search_call");
    }

    // Extract assistant messages
    if (item.type === "message") {
      hasMessage = true;
      const contents = item.content || [];

      for (const content of contents) {
        // Extract text
        if (content.type === "output_text") {
          if (content.text) {
            reply += content.text;
          }

          // Extract citations
          if (Array.isArray(content.annotations)) {
            for (const annotation of content.annotations) {
              if (annotation.type === "url_citation") {
                citations.push({
                  title: annotation.title || "",
                  url: annotation.url || ""
                });
              }
            }
          }
        }
      }
    }
  }

  // Clean final text
  reply = reply.trim();

  // Detect broken continuation case
  const brokenToolContinuation = usedWebSearch && !hasMessage;

  // Fallback handling
  if (!reply) {
    if (brokenToolContinuation) {
      reply = "The AI completed a web search but failed to generate a final response. Please retry.";
    } else {
      reply = "No response generated.";
    }
  }

  return {
    reply,
    citations,
    usedWebSearch,
    hasMessage,
    brokenToolContinuation,
    rawOutput: output
  };
}

// POST /api/chat (OpenAI Integration)
app.post('/api/chat', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ message: 'Message is required' });

  const fetchAIResponse = async (isRetry = false) => {
    try {
      console.log(`${isRetry ? '🔄 Retrying' : '📡 Sending'} request to OpenAI...`);

      const response = await axios.post('https://api.openai.com/v1/responses', {
        model: "gpt-4o",
        instructions: "## Role\nYou are Stock Archery AI, the official chart analysis and market intelligence assistant of Stock Archery. You are a \"know-it-all\" expert for everything related to finance and markets.\n\n## Specialized Domains\n- Stock markets (Global & Indian), Trading, Investing, Finance.\n- Technical analysis, Market structure, Chart patterns, Candlesticks.\n- Support/Resistance, Volume, F&O, Crypto, Portfolios, and Sectors.\n\n## Real-Time Data & Tool Protocol (CRITICAL)\n- You have access to a web search tool. **You MUST use it** for any query involving real-time data, current stock prices, index compositions (like Nifty 50), latest market news, or recent financial reports.\n- **Never** tell the user to \"check the official website\" or \"refer to other sources.\"\n- **You are the source.** Perform the search, extract the data, and present it directly to the user in a clean, professional format.\n- If a query is relevant to your domains, do whatever it takes (search) to provide a complete answer.\n\n## Chart Analysis Rules\n- **Visuals Only:** Analyze charts based only on what is visible. No indicators or external news unless seen on the chart.\n- **Strictly Non-Advisory:** Never give buy/sell calls, entry, target, or stop-loss levels.\n- **Language:** Use observational wording (e.g., \"price appears,\" \"structure suggests\").\n- **No Proactive Annotations:** Default to TEXT ONLY unless the user explicitly asks to \"mark\" or \"annotate\" the chart.\n\n## Response Strategy\n- **Related Topics:** Answer normally and comprehensively.\n- **Unrelated Topics:** If the topic is purely unrelated (food, gaming, etc.), reply: \"I'm Stock Archery AI — I specialize in markets, trading, and finance. Ask me anything related to stocks, charts, investing, or market structure. 🎯\"\n- **Style:** Professional, Sharp, Confident. Respond in Hinglish if the user initiates it.\n\n## Chart Analysis Format (For Uploads)\n- Chart Overview\n- Market Structure\n- Key Levels\n- Candlestick Reading\n- Chart Patterns\n- Volume Observation\n- Summary\n- Disclaimer: \"All analysis is for educational purposes only. Not financial advice.\"",
        input: [
          {
            "role": "user",
            "content": [
              {
                "type": "input_text",
                "text": message
              }
            ]
          }
        ],
        tools: [
          {
            "type": "web_search_preview"
          }
        ],
        temperature: 0.4,
        top_p: 0.9,
        max_output_tokens: 1000
      }, {
        headers: {
          'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
          'Content-Type': 'application/json'
        }
      });

      console.log("📥 Raw OpenAI Output Array:", JSON.stringify(response.data.output, null, 2));

      const parsed = parseOpenAIResponse(response.data);

      // Handle broken tool continuation with a single retry
      if (parsed.brokenToolContinuation && !isRetry) {
        console.warn("⚠️ Broken tool continuation detected. Attempting automatic retry...");
        return await fetchAIResponse(true);
      }

      console.log("✅ Final Parsed Response:", {
        hasMessage: parsed.hasMessage,
        usedWebSearch: parsed.usedWebSearch,
        citationCount: parsed.citations.length
      });

      return res.json(parsed);

    } catch (err) {
      console.error('OpenAI API Error:', err.response ? JSON.stringify(err.response.data, null, 2) : err.message);
      return res.status(500).json({ message: 'AI processing failed', error: err.message });
    }
  };

  await fetchAIResponse();
});

// POST /api/chart-analysis (Image-based technical analysis)
app.post('/api/chart-analysis', async (req, res) => {
  const { message, image } = req.body; // 'image' should be base64 string
  if (!message || !image) {
    return res.status(400).json({ message: 'Both message and image are required for chart analysis' });
  }

  const fetchChartAnalysis = async (isRetry = false) => {
    try {
      console.log(`${isRetry ? '🔄 Retrying' : '📡 Sending'} chart analysis request to OpenAI...`);

      const response = await axios.post('https://api.openai.com/v1/responses', {
        model: "gpt-4o",
        instructions: "## Role\nYou are Stock Archery AI, the official chart analysis and market intelligence assistant of Stock Archery. You are a \"know-it-all\" expert for everything related to finance and markets.\n\n## Specialized Domains\n- Stock markets (Global & Indian), Trading, Investing, Finance.\n- Technical analysis, Market structure, Chart patterns, Candlesticks.\n- Support/Resistance, Volume, F&O, Crypto, Portfolios, and Sectors.\n\n## Chart Analysis Rules (CRITICAL)\n- Analyze the provided chart based ONLY on what is visible.\n- **Strictly Non-Advisory:** Never give buy/sell calls, entry, target, or stop-loss levels.\n- **Language:** Use observational wording (e.g., \"price appears,\" \"structure suggests\").\n- **Output Format:** Provide a structured technical analysis (Overview, Levels, Patterns, Summary).\n- **Mandatory Disclaimer:** Every response MUST end with exactly: \"All analysis is for educational purposes only. Not financial advice.\"\n\n## Response Strategy\n- Professional, Sharp, Confident. Respond in Hinglish if the user initiates it.",
        input: [
          {
            "role": "user",
            "content": [
              {
                "type": "input_text",
                "text": message
              },
              {
                "type": "input_image",
                "image_url":
                  `data:image/jpeg;base64,${image}`

              }
            ]
          }
        ],
        temperature: 0.4,
        top_p: 0.9,
        max_output_tokens: 1500
      }, {
        headers: {
          'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
          'Content-Type': 'application/json'
        }
      });

      console.log("📥 Raw Chart Analysis Output:", JSON.stringify(response.data.output, null, 2));

      const parsed = parseOpenAIResponse(response.data);

      if (parsed.brokenToolContinuation && !isRetry) {
        return await fetchChartAnalysis(true);
      }

      // Ensure the disclaimer is present (double-check in case AI missed it)
      const disclaimer = "\n\nAll analysis is for educational purposes only. Not financial advice.";
      if (!parsed.reply.includes("educational purposes only")) {
        parsed.reply += disclaimer;
      }

      return res.json(parsed);

    } catch (err) {
      console.error('Chart Analysis Error:', err.response ? JSON.stringify(err.response.data, null, 2) : err.message);
      return res.status(500).json({ message: 'Chart analysis failed', error: err.message });
    }
  };

  await fetchChartAnalysis();
});

app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});