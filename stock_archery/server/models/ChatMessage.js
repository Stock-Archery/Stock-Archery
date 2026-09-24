const mongoose = require('mongoose');

const citationSchema = new mongoose.Schema(
  { title: String, url: String },
  { _id: false }
);

// One document per chat message. Kept out of the User document on purpose:
// the history grows without bound and User is a hot document.
const chatMessageSchema = new mongoose.Schema(
  {
    firebaseUid: { type: String, required: true },
    // One thread per app tab: the text chat and the chart-analysis chat.
    threadType: { type: String, enum: ['text', 'chart'], required: true },
    // Always 'default' for now (one thread per tab). Kept so multiple
    // conversations per user can be added later without a migration.
    conversationId: { type: String, default: 'default' },
    role: { type: String, enum: ['user', 'assistant'], required: true },
    content: { type: String, required: true },
    // Assistant messages only. For display; never sent back to the model.
    citations: { type: [citationSchema], default: [] },
    // Chart messages only: the image lives in ImageKit, not in Mongo.
    imageUrl: { type: String, default: null },
    imageFileId: { type: String, default: null },
    createdAt: { type: Date, default: Date.now },
    // TTL: Mongo deletes the document once this date passes.
    expiresAt: { type: Date, required: true },
  },
  { collection: 'chat_messages' }
);

chatMessageSchema.index({
  firebaseUid: 1,
  threadType: 1,
  conversationId: 1,
  createdAt: -1,
});
chatMessageSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('ChatMessage', chatMessageSchema);
