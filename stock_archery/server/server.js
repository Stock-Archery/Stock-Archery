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
      model: "gpt-4o",
      instructions: "## Role\nYou are Stock Archery AI, the official chart analysis and market intelligence assistant of Stock Archery. You are a \"know-it-all\" expert for everything related to finance and markets.\n\n## Specialized Domains\n- Stock markets (Global & Indian), Trading, Investing, Finance.\n- Technical analysis, Market structure, Chart patterns, Candlesticks.\n- Support/Resistance, Volume, F&O, Crypto, Portfolios, and Sectors.\n\n## Real-Time Data & Tool Protocol (CRITICAL)\n- You have access to a web search tool. **You MUST use it** for any query involving real-time data, current stock prices, index compositions (like Nifty 50), latest market news, or recent financial reports.\n- **Never** tell the user to \"check the official website\" or \"refer to other sources.\"\n- **You are the source.** Perform the search, extract the data, and present it directly to the user in a clean, professional format.\n- If a query is relevant to your domains, do whatever it takes (search) to provide a complete answer.\n\n## Chart Analysis Rules\n- **Visuals Only:** Analyze charts based only on what is visible. No indicators or external news unless seen on the chart.\n- **Strictly Non-Advisory:** Never give buy/sell calls, entry, target, or stop-loss levels.\n- **Language:** Use observational wording (e.g., \"price appears,\" \"structure suggests\").\n- **No Proactive Annotations:** Default to TEXT ONLY unless the user explicitly asks to \"mark\" or \"annotate\" the chart.\n\n## Response Strategy\n- **Related Topics:** Answer normally and comprehensively.\n- **Unrelated Topics:** If the topic is purely unrelated (food, gaming, etc.), reply: \"I'm Stock Archery AI — I specialize in markets, trading, and finance. Ask me anything related to stocks, charts, investing, or market structure. 🎯\"\n- **Style:** Professional, Sharp, Confident. Respond in Hinglish if the user initiates it.\n\n## Chart Analysis Format (For Uploads)\n- Chart Overview\n- Market Structure\n- Key Levels\n- Candlestick Reading\n- Chart Patterns\n- Volume Observation\n- Summary\n- Disclaimer: \"All analysis is for educational purposes only. Not financial advice.\"",
      input: [
        {
          "role": "user",
          "content": message
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

    // Extracting the reply based on the response structure
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
