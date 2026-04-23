import { useEffect, useRef, useState } from "react";
import type { HarnessEvent } from "../lib/types";

export function useWebSocket(url: string = "/ws") {
  const [events, setEvents] = useState<HarnessEvent[]>([]);
  const [connected, setConnected] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    const absolute =
      url.startsWith("ws://") || url.startsWith("wss://")
        ? url
        : `${location.protocol === "https:" ? "wss:" : "ws:"}//${location.host}${url}`;
    const ws = new WebSocket(absolute);
    wsRef.current = ws;
    ws.onopen = () => setConnected(true);
    ws.onclose = () => setConnected(false);
    ws.onmessage = (ev) => {
      try {
        const parsed = JSON.parse(ev.data) as HarnessEvent;
        setEvents((prev) => [...prev.slice(-499), parsed]);
      } catch {}
    };
    return () => ws.close();
  }, [url]);

  return { events, connected };
}
