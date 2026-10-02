function formatDate(value) {
  if (!value) return "—";
  return new Date(value).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" });
}

function Row({ label, value }) {
  return (
    <div className="detail-row">
      <span className="detail-label">{label}</span>
      <span className="detail-value">{value ?? "—"}</span>
    </div>
  );
}

export default function UserDetailModal({ user, onClose }) {
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{user.name}</h2>
          <button type="button" className="btn-ghost" onClick={onClose}>✕</button>
        </div>

        <div className="modal-body">
          <Row label="Email" value={user.email} />
          <Row label="Phone" value={user.phoneNumber} />
          <Row label="State" value={user.state} />
          <Row label="Occupation" value={user.occupation} />
          <Row label="Trading Experience" value={user.tradingExperience} />
          <Row label="Gender" value={user.gender} />
          <Row label="Firebase UID" value={user.firebaseUid} />

          <hr />

          <Row
            label="Premium"
            value={user.isPremium ? `Yes, until ${formatDate(user.premiumExpiresAt)}` : "No"}
          />
          <Row
            label="SOB Alert"
            value={user.isSOB_alert_premium ? `Yes, until ${formatDate(user.SOB_alert_expiresAt)}` : "No"}
          />
          <Row
            label="Xaud Alert"
            value={user.isXaud_alert_premium ? `Yes, until ${formatDate(user.Xaud_alert_expiresAt)}` : "No"}
          />
          <Row
            label="Crypto Alert"
            value={user.isCrypto_alert_premium ? `Yes, until ${formatDate(user.Crypto_alert_expiresAt)}` : "No"}
          />

          <hr />

          <Row label="Chats Today" value={user.textChatCount ?? 0} />
          <Row label="Registered Devices" value={(user.fcmTokens || []).length} />
          <Row label="Signed Up" value={formatDate(user.createdAt)} />
          <Row label="Last Updated" value={formatDate(user.updatedAt)} />
        </div>
      </div>
    </div>
  );
}
