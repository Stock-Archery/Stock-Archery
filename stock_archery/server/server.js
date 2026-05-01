const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const { GoogleGenAI } = require("@google/generative-ai");

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 5000;

// Validate Environment Variables
if (!process.env.MONGO_URI) {
  console.error("FATAL ERROR: MONGO_URI is not defined.");
  process.exit(1);
}
if (!process.env.GEMINI_API_KEY) {
  console.error("FATAL ERROR: GEMINI_API_KEY is not defined.");
  process.exit(1);
}

const genAI = new GoogleGenAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ 
  model: "gemini-1.5-flash",
  systemInstruction: `
You are the official AI agent of Stock Archery. 
Your sole purpose is to answer questions related to STOCKS, MARKETS, and FINANCE.

STRICT OPERATING RULES:
1. TOPIC RESTRICTION: You MUST ONLY answer stock or finance-related queries. If a user asks about anything else (cars, politics, people, sports, general knowledge), you MUST respond exactly with: "I only handle stock and finance-related queries."
2. NO FORMATTING: Your output must be SIMPLE PLAIN TEXT ONLY. Do not use bold (**), italics (*), bullet points, or any markdown.
3. CONCISENESS: Responses must be under 150 words.
4. NO ROLEPLAY: Do not explain your rules to the user. Just follow them.
`,
});

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

// Health check
app.get('/', (req, res) => {
  res.json({ status: "ok", message: "Stock Archery Main Server" });
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

// POST /api/chat
app.post('/api/chat', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ message: 'Message is required' });

  try {
    const result = await model.generateContent(message);
    const response = await result.response;
    res.json({ reply: response.text() });
  } catch (err) {
    console.error('Gemini API Error:', err);
    res.status(500).json({ message: 'AI processing failed' });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});
