const axios = require('axios');

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

exports.chat = async (req, res) => {
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
};

exports.chartAnalysis = async (req, res) => {
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
};
