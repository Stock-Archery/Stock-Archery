import { useServerStatus, ServerAwakeState } from "../hooks/useServerStatus.js";

function StatusDot({ state }) {
  const colors = {
    [ServerAwakeState.unknown]: "#94a3b8",
    [ServerAwakeState.checking]: "#6366f1",
    [ServerAwakeState.waking]: "#f97316",
    [ServerAwakeState.awake]: "#22c55e",
  };
  return (
    <span
      style={{
        display: "inline-block",
        width: 12,
        height: 12,
        borderRadius: "50%",
        background: colors[state] ?? "#94a3b8",
        flexShrink: 0,
      }}
    />
  );
}

function subtitle(state, attempt) {
  switch (state) {
    case ServerAwakeState.unknown:   return "Not checked yet";
    case ServerAwakeState.checking:  return "Pinging server…";
    case ServerAwakeState.waking:    return `Retrying in background (try ${attempt}) — click to stop`;
    case ServerAwakeState.awake:     return "Server is live";
    default:                          return "";
  }
}

export default function ServerAwakeTracker() {
  const { state, attempt, check, cancel } = useServerStatus();

  const isAwake    = state === ServerAwakeState.awake;
  const isChecking = state === ServerAwakeState.checking;
  const isWaking   = state === ServerAwakeState.waking;

  return (
    <div className="server-tracker">
      <StatusDot state={state} />

      <div className="server-tracker-text">
        <span className="server-tracker-title">Backend Server</span>
        <span className="server-tracker-sub" data-state={state}>
          {subtitle(state, attempt)}
        </span>
      </div>

      {isAwake ? (
        <div className="server-badge-ready">
          ✓ Ready to use
        </div>
      ) : isChecking || isWaking ? (
        <button
          type="button"
          className="server-btn-busy"
          onClick={isWaking ? cancel : undefined}
          disabled={isChecking}
        >
          <span className="server-spinner" /> {isWaking ? "Waking up… (cancel)" : "Checking…"}
        </button>
      ) : (
        <button type="button" className="server-btn-check" onClick={check}>
          Check
        </button>
      )}
    </div>
  );
}
