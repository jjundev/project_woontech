import { useEffect, useMemo, useRef, useState } from "react";
import type { HarnessEvent } from "../lib/types";
import {
  agentStyle,
  phaseLabel,
  relativeTime,
} from "../lib/timeline";

type ChatItem =
  | { kind: "text"; text: string; ts: number }
  | { kind: "tool"; tool: string; input: Record<string, unknown>; ts: number };

interface ChatGroup {
  key: string;
  agent: string;
  iteration?: number;
  startTs: number;
  endTs: number;
  items: ChatItem[];
  finished: boolean;
  stopReason?: string;
}

interface PhaseDivider {
  kind: "divider";
  key: string;
  phase: string;
  iteration?: number;
  ts: number;
}

type Row = (ChatGroup & { kind: "group" }) | PhaseDivider;

export function ChatTimeline({ events }: { events: HarnessEvent[] }) {
  const [now, setNow] = useState(() => Date.now());
  const containerRef = useRef<HTMLDivElement | null>(null);
  const stickToBottomRef = useRef(true);

  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  const rows = useMemo(() => buildRows(events), [events]);

  useEffect(() => {
    const el = containerRef.current;
    if (!el || !stickToBottomRef.current) return;
    el.scrollTop = el.scrollHeight;
  }, [rows.length, events.length]);

  const onScroll = () => {
    const el = containerRef.current;
    if (!el) return;
    const distance = el.scrollHeight - (el.scrollTop + el.clientHeight);
    stickToBottomRef.current = distance < 24;
  };

  return (
    <div
      ref={containerRef}
      onScroll={onScroll}
      className="flex-1 overflow-auto p-2 space-y-2 text-xs"
    >
      {rows.length === 0 && (
        <div className="text-slate-500 px-2 py-3">No agent activity yet.</div>
      )}
      {rows.map((row) =>
        row.kind === "divider" ? (
          <PhaseDividerRow key={row.key} phase={row.phase} iteration={row.iteration} />
        ) : (
          <ChatBubble key={row.key} group={row} now={now} />
        ),
      )}
    </div>
  );
}

function buildRows(events: HarnessEvent[]): Row[] {
  const rows: Row[] = [];
  let current: ChatGroup | null = null;

  const flush = () => {
    if (current) {
      rows.push({ ...current, kind: "group" } as Row);
      current = null;
    }
  };

  const groupKey = (agent: string, iteration: number | undefined, ts: number) =>
    `${agent}::${iteration ?? "_"}::${ts}`;

  for (const event of events) {
    if (event.type === "phase_started") {
      flush();
      const phase = String(event.payload?.phase ?? "");
      rows.push({
        kind: "divider",
        key: `divider:${event.ts}:${phase}:${event.iteration ?? ""}`,
        phase,
        iteration: event.iteration,
        ts: event.ts,
      });
      continue;
    }

    if (event.type === "agent_started") {
      flush();
      const agent = event.agent ?? "agent";
      current = {
        key: groupKey(agent, event.iteration, event.ts),
        agent,
        iteration: event.iteration,
        startTs: event.ts,
        endTs: event.ts,
        items: [],
        finished: false,
      };
      continue;
    }

    if (event.type === "agent_finished") {
      if (current && current.agent === (event.agent ?? current.agent)) {
        current.finished = true;
        current.stopReason = (event.payload?.stop_reason as string) ?? undefined;
        current.endTs = event.ts;
        flush();
      }
      continue;
    }

    if (event.type === "agent_text") {
      const agent = event.agent ?? "agent";
      if (
        !current ||
        current.agent !== agent ||
        current.iteration !== event.iteration ||
        current.finished
      ) {
        flush();
        current = {
          key: groupKey(agent, event.iteration, event.ts),
          agent,
          iteration: event.iteration,
          startTs: event.ts,
          endTs: event.ts,
          items: [],
          finished: false,
        };
      }
      current.items.push({
        kind: "text",
        text: String(event.payload?.text ?? ""),
        ts: event.ts,
      });
      current.endTs = event.ts;
      continue;
    }

    if (event.type === "agent_tool_call") {
      const agent = event.agent ?? "agent";
      if (
        !current ||
        current.agent !== agent ||
        current.iteration !== event.iteration ||
        current.finished
      ) {
        flush();
        current = {
          key: groupKey(agent, event.iteration, event.ts),
          agent,
          iteration: event.iteration,
          startTs: event.ts,
          endTs: event.ts,
          items: [],
          finished: false,
        };
      }
      current.items.push({
        kind: "tool",
        tool: String(event.payload?.tool ?? "tool"),
        input: (event.payload?.input as Record<string, unknown>) ?? {},
        ts: event.ts,
      });
      current.endTs = event.ts;
      continue;
    }
    // Other event types (state_changed, file_changed, agent_usage, plan_*) are
    // intentionally not rendered in the chat view — they live in the Events tab.
  }

  flush();
  return rows;
}

function PhaseDividerRow({ phase, iteration }: { phase: string; iteration?: number }) {
  return (
    <div className="flex items-center gap-2 pt-2 pb-0.5">
      <div className="flex-1 h-px bg-slate-800" />
      <span className="uppercase tracking-wide text-[10px] text-indigo-300 font-semibold">
        {phaseLabel(phase)}
        {iteration !== undefined && ` · iter ${iteration}`}
      </span>
      <div className="flex-1 h-px bg-slate-800" />
    </div>
  );
}

function ChatBubble({ group, now }: { group: ChatGroup; now: number }) {
  const style = agentStyle(group.agent);
  const [expanded, setExpanded] = useState(false);
  const headerLabel = group.iteration !== undefined ? `${style.label} · iter ${group.iteration}` : style.label;

  // Render every item in chronological order. Text wraps; tool calls appear as
  // small chips inline. When collapsed, clamp the visible height.
  return (
    <div
      className={`rounded-md border ${style.border} ${style.bubble} px-2.5 py-2 transition-colors`}
    >
      <div className="flex items-baseline gap-2 mb-1">
        <span className={`font-semibold ${style.text}`}>{headerLabel}</span>
        {group.finished && (
          <span className="text-[10px] text-slate-500" title={group.stopReason ?? "finished"}>
            · finished
          </span>
        )}
        <span className="flex-1" />
        <span
          className="text-[10px] text-slate-500 shrink-0"
          title={new Date(group.endTs * 1000).toLocaleString()}
        >
          {relativeTime(group.endTs, now)}
        </span>
      </div>
      <div
        className={`space-y-1.5 ${expanded ? "" : "max-h-56 overflow-hidden relative"}`}
        onDoubleClick={() => setExpanded((v) => !v)}
      >
        {group.items.map((item, i) =>
          item.kind === "text" ? (
            <TextSegment key={i} text={item.text} />
          ) : (
            <ToolChip key={i} tool={item.tool} input={item.input} chipClass={style.chip} />
          ),
        )}
        {!expanded && group.items.length > 0 && (
          <div className={`pointer-events-none absolute inset-x-0 bottom-0 h-8 bg-gradient-to-t from-current to-transparent opacity-0`} />
        )}
      </div>
      {group.items.length > 1 && (
        <button
          onClick={() => setExpanded((v) => !v)}
          className="mt-1 text-[10px] text-slate-500 hover:text-slate-300"
        >
          {expanded ? "Collapse" : "Expand"}
        </button>
      )}
    </div>
  );
}

function TextSegment({ text }: { text: string }) {
  const trimmed = text.trim();
  if (!trimmed) return null;
  return (
    <div className="whitespace-pre-wrap text-slate-200 text-[12px] leading-snug font-sans">
      {trimmed}
    </div>
  );
}

function ToolChip({
  tool,
  input,
  chipClass,
}: {
  tool: string;
  input: Record<string, unknown>;
  chipClass: string;
}) {
  const [open, setOpen] = useState(false);
  const summary = toolSummary(tool, input);
  return (
    <div className="text-[11px]">
      <button
        onClick={() => setOpen((v) => !v)}
        className={`inline-flex items-baseline gap-1.5 px-1.5 py-0.5 rounded ${chipClass} hover:brightness-125 transition-all`}
        title="Click to inspect tool input"
      >
        <span className="font-mono">⚙</span>
        <span className="font-medium">{tool}</span>
        {summary && <span className="opacity-80 font-mono break-all">{summary}</span>}
      </button>
      {open && (
        <pre className="mt-1 ml-1 p-1.5 rounded bg-slate-950/70 border border-slate-800 text-[10px] text-slate-300 whitespace-pre-wrap break-all font-mono">
          {JSON.stringify(input, null, 2)}
        </pre>
      )}
    </div>
  );
}

function toolSummary(tool: string, input: Record<string, unknown>): string {
  const fp =
    (input.file_path as string | undefined) ||
    (input.path as string | undefined) ||
    (input.notebook_path as string | undefined) ||
    (input.command as string | undefined) ||
    (input.pattern as string | undefined) ||
    "";
  if (!fp) return "";
  const max = tool === "Bash" ? 80 : 60;
  return fp.length > max ? `${fp.slice(0, max - 1)}…` : fp;
}
