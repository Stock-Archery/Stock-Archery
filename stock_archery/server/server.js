const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const axios = require('axios');

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

// POST /api/chat (OpenAI Integration)
app.post('/api/chat', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ message: 'Message is required' });

  try {
    const response = await axios.post('https://api.openai.com/v1/responses', {
      model: "gpt-4.1-nano",
      input: message,
      instructions: "You are the official AI agent of Stock Archery, a specialized trading firm. Your sole purpose is to provide expert guidance on stocks and finance. " + 
                    "STRICT RULES: " + 
                    "1. ONLY answer questions related to stocks, financial markets, and general finance. " + 
                    "2. If a user asks about any other topic (politics, sports, general knowledge, etc.), politely but firmly deny the request by stating that you only handle stock and finance queries. " + 
                    "3. Your responses must be in simple, plain text only. DO NOT use any markdown formatting, bolding (**), italics (*), or other text decorations. " + 
                    "4. Keep all responses concise, with a maximum limit of 200 words.",
      max_output_tokens: 120
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    // Extracting the reply based on the specific gpt-4.1-nano response structure
    const reply = response.data.output[0].content[0].text || "No response from AI.";
    res.json({ reply: reply });

  } catch (err) {
    console.error('OpenAI API Error:', err.response ? err.response.data : err.message);
    res.status(500).json({ message: 'AI processing failed' });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});
