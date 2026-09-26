const axios = require('axios');
const User = require('../models/User');
const ChatMessage = require('../models/ChatMessage');
const imagekit = require('../services/imagekit');

// India has a single fixed UTC+5:30 offset year-round (no DST), so the free
// daily chat limit can reset at IST midnight with a constant offset instead
// of a timezone library. Returns the IST calendar day as "YYYY-MM-DD".
const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;
function istDateKey(date = new Date()) {
  return new Date(date.getTime() + IST_OFFSET_MS).toISOString().slice(0, 10);
}

// ── Chat history / context window ────────────────────────────────────────────
// History lives in MongoDB and is assembled here on the server — the client
// never sends it, so a user can't inflate the prompt or fake earlier turns.
const HISTORY_MESSAGES = { free: 4, premium: 16 };
// Rough cap on history sent to the model (~4 chars per token ≈ 3k tokens).
const HISTORY_CHAR_BUDGET = 12000;
const MAX_MESSAGE_LENGTH = 2000;
const RETENTION_DAYS = { free: 90, premium: 365 };
const THREAD_TYPES = ['text', 'chart'];

// Returns the recent messages of a thread as Responses API input items,
// oldest first. Text only: citations and old images are never re-sent.
async function loadHistoryInput(uid, threadType, isPremium) {
  const limit = isPremium ? HISTORY_MESSAGES.premium : HISTORY_MESSAGES.free;
  const recent = await ChatMessage.find({
    firebaseUid: uid,
    threadType,
    conversationId: 'default',
  })
    .sort({ createdAt: -1 })
    .limit(limit)
    .lean();

  // Walk newest → oldest, keeping messages until the budget is spent. The
  // newest message is always kept even if it alone is over budget.
  const kept = [];
  let used = 0;
  for (const m of recent) {
    used += m.content.length;
    if (used > HISTORY_CHAR_BUDGET && kept.length > 0) break;
    kept.push(m);
  }
  kept.reverse();

  return kept.map((m) =>
    m.role === 'assistant'
      ? { role: 'assistant', content: [{ type: 'output_text', text: m.content }] }
      : { role: 'user', content: [{ type: 'input_text', text: m.content }] }
  );
}

// The most recent chart image stored in this thread (its ImageKit URL), or
// null. Used so a follow-up question needs no new upload: the model is shown
// the same chart again.
async function findLatestImageUrl(uid, threadType) {
  const m = await ChatMessage.findOne({
    firebaseUid: uid,
    threadType,
    conversationId: 'default',
    imageUrl: { $ne: null },
  })
    .sort({ createdAt: -1 })
    .select('imageUrl')
    .lean();
  return m ? m.imageUrl : null;
}

// Saves one user→assistant exchange. Called only after the model answered,
// so a failed OpenAI call never leaves an orphaned user message behind.
async function saveExchange({ uid, threadType, isPremium, userText, requestedAt, assistantText, citations, image }) {
  const answeredAt = Math.max(Date.now(), requestedAt + 1);
  const days = isPremium ? RETENTION_DAYS.premium : RETENTION_DAYS.free;
  const expiresAt = new Date(answeredAt + days * 24 * 60 * 60 * 1000);

  await ChatMessage.insertMany(
    [
      {
        firebaseUid: uid,
        threadType,
        role: 'user',
        content: userText,
        imageUrl: image?.url || null,
        imageFileId: image?.fileId || null,
        createdAt: new Date(requestedAt),
        expiresAt,
      },
      {
        firebaseUid: uid,
        threadType,
        role: 'assistant',
        content: assistantText,
        citations: citations || [],
        createdAt: new Date(answeredAt),
        expiresAt,
      },
    ],
    { ordered: true }
  );
}

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
  const uid = req.user.uid;
  const requestedAt = Date.now();
  if (!message) return res.status(400).json({ message: 'Message is required' });
  if (typeof message !== 'string' || message.length > MAX_MESSAGE_LENGTH) {
    return res.status(400).json({ message: `Message must be a string of at most ${MAX_MESSAGE_LENGTH} characters` });
  }

  let user;
  try {
    user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: 'User not found' });
  } catch (err) {
    return res.status(500).json({ message: 'Database error', error: err.message });
  }

  // Premium status is always derived from the authenticated user's own DB
  // record, never from the client-supplied body — a client-controlled flag
  // here would let anyone bypass the free-chat limit by sending isPremium:true.
  const isPremium = user.isPremium === true;

  // The 5-message limit is PER IST CALENDAR DAY, not lifetime. There's no
  // separate reset job: textChatCount is only ever meaningful alongside
  // textChatCountDate, so a stale (or missing, for pre-existing users) date
  // just means "effectively 0 today" — the actual reset happens atomically
  // on the next counted increment below.
  const todayKey = istDateKey();
  const effectiveCount = user.textChatCountDate === todayKey ? user.textChatCount : 0;

  if (!isPremium && effectiveCount >= 5) {
    return res.status(403).json({ limitReached: true, message: 'Free daily chat limit reached. Try again tomorrow.' });
  }

  // Context window. A history failure must never block the chat itself.
  let historyInput = [];
  try {
    historyInput = await loadHistoryInput(uid, 'text', isPremium);
  } catch (err) {
    console.error('Failed to load chat history (continuing without context):', err.message);
  }

  const fetchAIResponse = async (isRetry = false) => {
    try {
      console.log(`${isRetry ? '🔄 Retrying' : '📡 Sending'} request to OpenAI...`);

      const response = await axios.post('https://api.openai.com/v1/responses', {
        model: "gpt-4o",
        instructions: "## Role\nYou are Stock Archery AI, the official chart analysis and market intelligence assistant of Stock Archery. You are a \"know-it-all\" expert for everything related to finance and markets.\n\n## Specialized Domains\n- Stock markets (Global & Indian), Trading, Investing, Finance.\n- Technical analysis, Market structure, Chart patterns, Candlesticks.\n- Support/Resistance, Volume, F&O, Crypto, Portfolios, and Sectors.\n\n## Real-Time Data & Tool Protocol (CRITICAL)\n- You have access to a web search tool. **You MUST use it** for any query involving real-time data, current stock prices, index compositions (like Nifty 50), latest market news, or recent financial reports.\n- **Never** tell the user to \"check the official website\" or \"refer to other sources.\"\n- **You are the source.** Perform the search, extract the data, and present it directly to the user in a clean, professional format.\n- If a query is relevant to your domains, do whatever it takes (search) to provide a complete answer.\n\n## Chart Analysis Rules\n- **Visuals Only:** Analyze charts based only on what is visible. No indicators or external news unless seen on the chart.\n- **Strictly Non-Advisory:** Never give buy/sell calls, entry, target, or stop-loss levels.\n- **Language:** Use observational wording (e.g., \"price appears,\" \"structure suggests\").\n- **No Proactive Annotations:** Default to TEXT ONLY unless the user explicitly asks to \"mark\" or \"annotate\" the chart.\n\n## Response Strategy\n- **Related Topics:** Answer normally and comprehensively.\n- **Unrelated Topics:** If the topic is purely unrelated (food, gaming, etc.), reply: \"I'm Stock Archery AI — I specialize in markets, trading, and finance. Ask me anything related to stocks, charts, investing, or market structure. 🎯\"\n- **Style:** Professional, Sharp, Confident. Respond in Hinglish if the user initiates it.\n\n## Chart Analysis Format (For Uploads)\n- Chart Overview\n- Market Structure\n- Key Levels\n- Candlestick Reading\n- Chart Patterns\n- Volume Observation\n- Summary\n- Disclaimer: \"All analysis is for educational purposes only. Not financial advice.\"",
        input: [
          ...historyInput,
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

      if (!isPremium && parsed.reply) {
        // Atomic reset-or-increment in a single pipeline update: if the
        // stored date still matches today, increment; otherwise this is the
        // first counted message of a new IST day, so reset to 1. Doing the
        // rollover and the increment in one atomic op (rather than a
        // separate read-then-write reset) avoids a lost update when a user
        // fires several concurrent /api/chat requests.
        await User.findOneAndUpdate(
          { _id: user._id },
          [
            {
              $set: {
                textChatCount: {
                  $cond: [
                    { $eq: ['$textChatCountDate', todayKey] },
                    { $add: ['$textChatCount', 1] },
                    1,
                  ],
                },
                textChatCountDate: todayKey,
              },
            },
          ],
          { updatePipeline: true }
        );
      }

      // Persist the exchange. Only real answers are saved (not the "no
      // response generated" fallbacks), and a save failure must not fail
      // a chat the user already got an answer for.
      if (parsed.hasMessage) {
        try {
          await saveExchange({
            uid,
            threadType: 'text',
            isPremium,
            userText: message,
            requestedAt,
            assistantText: parsed.reply,
            citations: parsed.citations,
          });
        } catch (saveErr) {
          console.error('Failed to save chat exchange:', saveErr.message);
        }
      }

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
  const uid = req.user.uid;
  const requestedAt = Date.now();

  let user;
  try {
    user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: 'User not found' });
  } catch (err) {
    return res.status(500).json({ message: 'Database error', error: err.message });
  }

  // Premium status is always derived from the authenticated user's own DB
  // record, never from the client-supplied body (see exports.chat above).
  if (!user.isPremium) {
    return res.status(403).json({ limitReached: true, message: 'Chart analysis is a premium feature' });
  }

  if (!message) {
    return res.status(400).json({ message: 'Message is required' });
  }
  if (typeof message !== 'string' || message.length > MAX_MESSAGE_LENGTH) {
    return res.status(400).json({ message: `Message must be a string of at most ${MAX_MESSAGE_LENGTH} characters` });
  }

  // The image is optional. A follow-up question about a chart already in this
  // thread needs no new upload: we re-attach the latest stored chart instead.
  const hasNewImage = typeof image === 'string' && image.length > 0;
  let followUpImageUrl = null;
  if (!hasNewImage) {
    try {
      followUpImageUrl = await findLatestImageUrl(uid, 'chart');
    } catch (err) {
      console.error('Failed to look up the latest chart image:', err.message);
    }
    if (!followUpImageUrl) {
      return res.status(400).json({ message: 'Please upload a chart image first.' });
    }
  }
  const imagePart = {
    type: 'input_image',
    image_url: hasNewImage ? `data:image/jpeg;base64,${image}` : followUpImageUrl,
  };

  // Upload to ImageKit while OpenAI works, instead of adding the upload's
  // latency on top. An upload failure only means the image isn't stored —
  // the analysis itself still goes ahead. Follow-ups upload nothing.
  const uploadPromise = hasNewImage
    ? imagekit.uploadChartImage(image, uid).catch((err) => {
        console.error('ImageKit upload failed (analysis continues without stored image):', err.message);
        return null;
      })
    : Promise.resolve(null);

  // Context window (text of earlier turns only — old images are never re-sent).
  let historyInput = [];
  try {
    historyInput = await loadHistoryInput(uid, 'chart', true);
  } catch (err) {
    console.error('Failed to load chart history (continuing without context):', err.message);
  }

  const fetchChartAnalysis = async (isRetry = false) => {
    try {
      console.log(`${isRetry ? '🔄 Retrying' : '📡 Sending'} chart analysis request to OpenAI...`);

      const response = await axios.post('https://api.openai.com/v1/responses', {
        model: "gpt-4o",
        instructions: "## Role\nYou are Stock Archery AI, the official chart analysis and market intelligence assistant of Stock Archery. You are a \"know-it-all\" expert for everything related to finance and markets.\n\n## Specialized Domains\n- Stock markets (Global & Indian), Trading, Investing, Finance.\n- Technical analysis, Market structure, Chart patterns, Candlesticks.\n- Support/Resistance, Volume, F&O, Crypto, Portfolios, and Sectors.\n\n## Chart Analysis Rules (CRITICAL)\n- Analyze the provided chart based ONLY on what is visible.\n- **Strictly Non-Advisory:** Never give buy/sell calls, entry, target, or stop-loss levels.\n- **Language:** Use observational wording (e.g., \"price appears,\" \"structure suggests\").\n- **Output Format:** Provide a structured technical analysis (Overview, Levels, Patterns, Summary).\n- **Mandatory Disclaimer:** Every response MUST end with exactly: \"All analysis is for educational purposes only. Not financial advice.\"\n\n## Response Strategy\n- Professional, Sharp, Confident. Respond in Hinglish if the user initiates it.",
        input: [
          ...historyInput,
          {
            "role": "user",
            "content": [
              {
                "type": "input_text",
                "text": message
              },
              imagePart
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

      // Persist the exchange with the ImageKit link for the chart image.
      if (parsed.hasMessage) {
        try {
          const stored = await uploadPromise;
          await saveExchange({
            uid,
            threadType: 'chart',
            isPremium: true,
            userText: message,
            requestedAt,
            assistantText: parsed.reply,
            citations: parsed.citations,
            image: stored,
          });
        } catch (saveErr) {
          console.error('Failed to save chart exchange:', saveErr.message);
        }
      } else {
        // No answer worth saving: don't leave the uploaded image orphaned.
        uploadPromise.then((stored) => stored && imagekit.deleteFiles([stored.fileId]));
      }

      return res.json(parsed);

    } catch (err) {
      console.error('Chart Analysis Error:', err.response ? JSON.stringify(err.response.data, null, 2) : err.message);
      // OpenAI failed: the image we uploaded has no message pointing at it.
      uploadPromise.then((stored) => stored && imagekit.deleteFiles([stored.fileId]));
      return res.status(500).json({ message: 'Chart analysis failed', error: err.message });
    }
  };

  await fetchChartAnalysis();
};

// ── History endpoints ────────────────────────────────────────────────────────

// GET /api/chat/history?type=text|chart&limit=30&before=<ISO date>
// Newest first, which is the order the client's chat list uses.
exports.getHistory = async (req, res) => {
  const uid = req.user.uid;
  const { type, before } = req.query;

  if (!THREAD_TYPES.includes(type)) {
    return res.status(400).json({ message: "type must be 'text' or 'chart'" });
  }

  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 30, 1), 50);
  const filter = { firebaseUid: uid, threadType: type, conversationId: 'default' };

  if (before) {
    const beforeDate = new Date(before);
    if (isNaN(beforeDate.getTime())) {
      return res.status(400).json({ message: 'before must be a valid ISO date' });
    }
    filter.createdAt = { $lt: beforeDate };
  }

  try {
    // Fetch one extra to know whether an older page exists.
    const docs = await ChatMessage.find(filter)
      .sort({ createdAt: -1 })
      .limit(limit + 1)
      .lean();

    const hasMore = docs.length > limit;
    const page = hasMore ? docs.slice(0, limit) : docs;

    return res.json({
      hasMore,
      messages: page.map((m) => ({
        id: m._id,
        role: m.role,
        text: m.content,
        citations: m.citations || [],
        imageUrl: m.imageUrl || null,
        createdAt: m.createdAt,
      })),
    });
  } catch (err) {
    console.error('Failed to load chat history:', err.message);
    return res.status(500).json({ message: 'Failed to load chat history' });
  }
};

// DELETE /api/chat/history?type=text|chart  — the user's "clear chat".
exports.clearHistory = async (req, res) => {
  const uid = req.user.uid;
  const { type } = req.query;

  if (!THREAD_TYPES.includes(type)) {
    return res.status(400).json({ message: "type must be 'text' or 'chart'" });
  }

  try {
    const filter = { firebaseUid: uid, threadType: type, conversationId: 'default' };
    const withImages = await ChatMessage.find({ ...filter, imageFileId: { $ne: null } })
      .select('imageFileId')
      .lean();

    const result = await ChatMessage.deleteMany(filter);

    // Best-effort: remove the images from ImageKit too.
    imagekit.deleteFiles(withImages.map((m) => m.imageFileId));

    return res.json({ status: 'success', deleted: result.deletedCount });
  } catch (err) {
    console.error('Failed to clear chat history:', err.message);
    return res.status(500).json({ message: 'Failed to clear chat history' });
  }
};
