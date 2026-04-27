import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
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

interface UiTestRun {
  kind: "ui_tests";
  key: string;
  iteration?: number;
  startTs: number;
  command: string;
  finished: boolean;
  exitCode?: number;
  durationS?: number;
  /** Live tail of stdout lines streamed via `ui_tests_output`. Capped to keep React re-render cheap. */
  lines: string[];
  /** Number of earlier lines dropped from the head of `lines` when the cap was hit. */
  truncated: number;
}

const UI_TEST_LINES_CAP = 400;

interface UiVerifyNoticeRow {
  kind: "ui_verify_notice";
  key: string;
  ts: number;
  variant: "skipped" | "failed" | "loopback" | "stalled";
  iteration?: number;
  text: string;
  detail?: string;
}

interface UiReviewProgressRow {
  kind: "ui_review_progress";
  key: string;
  ts: number;
  variant: "iter_progress" | "retry";
  iteration?: number;
  text: string;
}

type Row =
  | (ChatGroup & { kind: "group" })
  | PhaseDivider
  | UiTestRun
  | UiVerifyNoticeRow
  | UiReviewProgressRow;

export function ChatTimeline({ events }: { events: HarnessEvent[] }) {
  const [now, setNow] = useState(() => Date.now());
  const containerRef = useRef<HTMLDivElement | null>(null);
  const endRef = useRef<HTMLDivElement>(null);
  const stickToBottomRef = useRef(true);

  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  const rows = useMemo(() => buildRows(events), [events]);

  useLayoutEffect(() => {
    if (stickToBottomRef.current) {
      endRef.current?.scrollIntoView();
    }
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
      {rows.map((row) => {
        if (row.kind === "divider") {
          return <PhaseDividerRow key={row.key} phase={row.phase} iteration={row.iteration} />;
        }
        if (row.kind === "ui_tests") {
          return <UiTestRunRow key={row.key} run={row} now={now} />;
        }
        if (row.kind === "ui_verify_notice") {
          return <UiVerifyNotice key={row.key} row={row} />;
        }
        if (row.kind === "ui_review_progress") {
          return <UiReviewProgress key={row.key} row={row} />;
        }
        return <ChatBubble key={row.key} group={row} now={now} />;
      })}
      <div ref={endRef} />
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

    if (event.type === "ui_tests_started") {
      flush();
      const iteration = (event.payload?.iteration as number | undefined) ?? event.iteration;
      rows.push({
        kind: "ui_tests",
        key: `ui_tests:${event.ts}:${iteration ?? ""}`,
        iteration,
        startTs: event.ts,
        command: String(event.payload?.command ?? ""),
        finished: false,
        lines: [],
        truncated: 0,
      });
      continue;
    }

    if (event.type === "ui_tests_output") {
      const iteration = (event.payload?.iteration as number | undefined) ?? event.iteration;
      const line = String(event.payload?.line ?? "");
      // Append to the most recent un-finished ui_tests row with the same iteration.
      // If we somehow miss the `ui_tests_started` event, drop the line silently.
      for (let i = rows.length - 1; i >= 0; i--) {
        const row = rows[i];
        if (row.kind === "ui_tests" && !row.finished && row.iteration === iteration) {
          row.lines.push(line);
          if (row.lines.length > UI_TEST_LINES_CAP) {
            const drop = row.lines.length - UI_TEST_LINES_CAP;
            row.lines.splice(0, drop);
            row.truncated += drop;
          }
          break;
        }
      }
      continue;
    }

    if (event.type === "ui_tests_finished") {
      const iteration = (event.payload?.iteration as number | undefined) ?? event.iteration;
      // Match the most recent un-finished ui_tests row with the same iteration.
      for (let i = rows.length - 1; i >= 0; i--) {
        const row = rows[i];
        if (row.kind === "ui_tests" && !row.finished && row.iteration === iteration) {
          row.finished = true;
          row.exitCode = event.payload?.exit_code as number | undefined;
          row.durationS = event.payload?.duration_s as number | undefined;
          break;
        }
      }
      continue;
    }

    if (event.type === "ui_verify_skipped") {
      flush();
      rows.push({
        kind: "ui_verify_notice",
        key: `ui_verify_skipped:${event.ts}`,
        ts: event.ts,
        variant: "skipped",
        text: "UI verification skipped",
        detail: String(event.payload?.reason ?? ""),
      });
      continue;
    }

    if (event.type === "ui_verify_failed") {
      flush();
      const iteration = (event.payload?.iteration as number | undefined) ?? event.iteration;
      const reason = String(event.payload?.reason ?? "");
      const exitCode = event.payload?.exit_code;
      const detailParts: string[] = [];
      if (reason) detailParts.push(reason);
      if (exitCode !== undefined && exitCode !== null) detailParts.push(`exit ${exitCode}`);
      rows.push({
        kind: "ui_verify_notice",
        key: `ui_verify_failed:${event.ts}`,
        ts: event.ts,
        variant: "failed",
        iteration,
        text: "UI verification failed",
        detail: detailParts.join(" · "),
      });
      continue;
    }

    if (event.type === "ui_verify_rework_loopback") {
      flush();
      const iteration = (event.payload?.iteration as number | undefined) ?? event.iteration;
      const loop = event.payload?.loop;
      const maxLoops = event.payload?.max_loops;
      rows.push({
        kind: "ui_verify_notice",
        key: `ui_verify_loopback:${event.ts}`,
        ts: event.ts,
        variant: "loopback",
        iteration,
        text: "Looping back to implementor",
        detail:
          loop !== undefined && maxLoops !== undefined
            ? `rework ${loop}/${maxLoops}`
            : undefined,
      });
      continue;
    }

    if (event.type === "agent_stall" && event.payload?.phase === "ui_verify_review") {
      flush();
      const iteration = (event.payload?.iteration as number | undefined) ?? event.iteration;
      const headSha = event.payload?.head_sha;
      rows.push({
        kind: "ui_verify_notice",
        key: `ui_verify_stalled:${event.ts}`,
        ts: event.ts,
        variant: "stalled",
        iteration,
        text: "Reviewer made no changes — stalled",
        detail: headSha ? `head ${headSha}` : undefined,
      });
      continue;
    }

    if (event.type === "iter_progress" && event.payload?.phase === "ui_verify_review") {
      flush();
      const iteration = (event.payload?.iteration as number | undefined) ?? event.iteration;
      const pre = event.payload?.pre_sha;
      const post = event.payload?.post_sha;
      const shaText = pre && post ? `${pre} → ${post}` : String(post || pre || "");
      rows.push({
        kind: "ui_review_progress",
        key: `ui_review_iter:${event.ts}`,
        ts: event.ts,
        variant: "iter_progress",
        iteration,
        text: shaText
          ? `Reviewer applied changes (${shaText})`
          : "Reviewer applied changes",
      });
      continue;
    }

    if (event.type === "retry" && event.payload?.phase === "ui_verify_review") {
      flush();
      const iteration = (event.payload?.iteration as number | undefined) ?? event.iteration;
      const next = iteration !== undefined ? iteration + 1 : undefined;
      rows.push({
        kind: "ui_review_progress",
        key: `ui_review_retry:${event.ts}`,
        ts: event.ts,
        variant: "retry",
        iteration,
        text: next !== undefined ? `Retrying UI tests (iter ${next})` : "Retrying UI tests",
      });
      continue;
    }
    // Other event types (state_changed, file_changed, agent_usage, plan_*) are
    // intentionally not rendered in the chat view — they live in the Events tab.
  }

  flush();
  return rows;
}

function formatDuration(seconds: number): string {
  const total = Math.max(0, Math.floor(seconds));
  const m = Math.floor(total / 60);
  const s = total % 60;
  if (m === 0) return `${s}s`;
  return `${m}m ${s.toString().padStart(2, "0")}s`;
}

const UI_TEST_LINES_VISIBLE = 8;

function UiTestRunRow({ run, now }: { run: UiTestRun; now: number }) {
  const [expanded, setExpanded] = useState(false);
  const elapsedS = run.finished
    ? run.durationS ?? 0
    : Math.max(0, now / 1000 - run.startTs);
  const passed = run.finished && run.exitCode === 0;
  const failed = run.finished && run.exitCode !== 0;
  const label = run.finished
    ? passed
      ? `UI tests passed (${formatDuration(elapsedS)})`
      : `UI tests failed · exit ${run.exitCode} (${formatDuration(elapsedS)})`
    : `Running UI tests… ${formatDuration(elapsedS)}`;
  const stateClass = passed
    ? "border-emerald-700/60 bg-emerald-900/20 text-emerald-200"
    : failed
    ? "border-rose-700/60 bg-rose-900/20 text-rose-200"
    : "border-amber-700/60 bg-amber-900/20 text-amber-200";
  const totalLines = run.lines.length + run.truncated;
  const visibleLines = expanded ? run.lines : run.lines.slice(-UI_TEST_LINES_VISIBLE);
  const hiddenCount = expanded
    ? run.truncated
    : run.truncated + Math.max(0, run.lines.length - UI_TEST_LINES_VISIBLE);
  const hasLines = run.lines.length > 0;

  return (
    <div
      className={`rounded-md border ${stateClass} px-2.5 py-1.5`}
      title={run.command}
    >
      <div className="flex items-center gap-2">
        <span className="font-mono text-[10px]">{run.finished ? (passed ? "✓" : "✗") : "▶"}</span>
        <span className="font-medium text-[12px]">{label}</span>
        {run.iteration !== undefined && (
          <span className="text-[10px] opacity-70">· iter {run.iteration}</span>
        )}
        {hasLines && (
          <>
            <span className="flex-1" />
            <button
              onClick={() => setExpanded((v) => !v)}
              className="text-[10px] opacity-70 hover:opacity-100"
            >
              {expanded ? `collapse · ${totalLines} lines` : `show all · ${totalLines} lines`}
            </button>
          </>
        )}
      </div>
      {hasLines && (
        <div className="mt-1.5 rounded bg-slate-950/60 border border-slate-800/80 p-1.5 max-h-64 overflow-auto">
          {hiddenCount > 0 && (
            <div className="text-[10px] text-slate-500 italic mb-1">
              · {hiddenCount} earlier line{hiddenCount === 1 ? "" : "s"} hidden
            </div>
          )}
          <pre className="text-[10px] leading-snug text-slate-300 whitespace-pre-wrap break-all font-mono">
            {visibleLines.join("\n")}
          </pre>
        </div>
      )}
    </div>
  );
}

function UiVerifyNotice({ row }: { row: UiVerifyNoticeRow }) {
  const styles: Record<UiVerifyNoticeRow["variant"], { stateClass: string; icon: string }> = {
    skipped: { stateClass: "border-slate-700/60 bg-slate-900/40 text-slate-300", icon: "↷" },
    failed: { stateClass: "border-rose-700/60 bg-rose-900/20 text-rose-200", icon: "✗" },
    loopback: { stateClass: "border-amber-700/60 bg-amber-900/20 text-amber-200", icon: "↺" },
    stalled: { stateClass: "border-rose-700/60 bg-rose-900/20 text-rose-200", icon: "⏸" },
  };
  const { stateClass, icon } = styles[row.variant];
  return (
    <div className={`rounded-md border ${stateClass} px-2.5 py-1.5 flex items-center gap-2`}>
      <span className="font-mono text-[10px]">{icon}</span>
      <span className="font-medium text-[12px]">{row.text}</span>
      {row.iteration !== undefined && (
        <span className="text-[10px] opacity-70">· iter {row.iteration}</span>
      )}
      {row.detail && (
        <span className="text-[11px] opacity-80 font-mono break-all">· {row.detail}</span>
      )}
    </div>
  );
}

function UiReviewProgress({ row }: { row: UiReviewProgressRow }) {
  const icon = row.variant === "retry" ? "↻" : "↗";
  return (
    <div className="px-2 py-0.5 flex items-center gap-2 text-[11px] text-slate-400">
      <span className="font-mono">{icon}</span>
      <span>{row.text}</span>
      {row.iteration !== undefined && (
        <span className="opacity-70">· iter {row.iteration}</span>
      )}
    </div>
  );
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
