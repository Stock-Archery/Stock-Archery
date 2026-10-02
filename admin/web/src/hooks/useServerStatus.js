import { useState, useRef, useCallback } from "react";

const BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:3000";

// Mirrors the Flutter ServerStatusViewModel backoff sequence exactly.
const BACKOFFS = [3, 6, 12, 20, 30]; // seconds

export const ServerAwakeState = {
  unknown: "unknown",
  checking: "checking",
  waking: "waking",
  awake: "awake",
};

async function ping() {
  try {
    const res = await fetch(`${BASE_URL}/`, { signal: AbortSignal.timeout(15000) });
    return res.ok;
  } catch {
    return false;
  }
}

export function useServerStatus() {
  const [state, setState] = useState(ServerAwakeState.unknown);
  const [attempt, setAttempt] = useState(0);

  // Generation counter: incrementing it cancels any in-flight polling loop.
  const genRef = useRef(0);

  const check = useCallback(async () => {
    const isBusy = state === ServerAwakeState.checking || state === ServerAwakeState.waking;
    if (isBusy) return;

    const gen = ++genRef.current;
    setAttempt(0);
    setState(ServerAwakeState.checking);

    // Fast path — already awake
    if (await ping()) {
      if (genRef.current !== gen) return;
      setState(ServerAwakeState.awake);
      return;
    }

    // Server asleep — enter polling loop with progressive backoff
    if (genRef.current !== gen) return;
    setState(ServerAwakeState.waking);
    setAttempt(1);

    let backoffIndex = 0;
    while (genRef.current === gen) {
      const delay = BACKOFFS[Math.min(backoffIndex, BACKOFFS.length - 1)];
      await new Promise((resolve) => setTimeout(resolve, delay * 1000));
      if (genRef.current !== gen) return;

      setAttempt((a) => a + 1);
      if (await ping()) {
        if (genRef.current !== gen) return;
        setState(ServerAwakeState.awake);
        return;
      }
      backoffIndex++;
    }
  }, [state]);

  const cancel = useCallback(() => {
    genRef.current++;
    setState(ServerAwakeState.unknown);
    setAttempt(0);
  }, []);

  return { state, attempt, check, cancel };
}
