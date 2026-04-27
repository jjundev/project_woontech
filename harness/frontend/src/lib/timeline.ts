import type { HarnessEvent } from "./types";

export type EventCategory =
  | "control"
  | "success"
  | "warning"
  | "error"
  | "agent"
  | "file";

export type EventMeta = {
  category: EventCategory;
  icon: string;
  label: string;
  /** Short key facts to surface on the card without the user clicking to expand. */
  inline: Array<{ key: string; value: string }>;
};

/** Category → visual tokens. Used for the left border stripe, icon tint, and grouping. */
export const CATEGORY_STYLES: Record<EventCategory, { border: string; text: string; dot: string }> = {
  control: { border: "border-l-indigo-500", text: "text-indigo-300", dot: "bg-indigo-500" },
  success: { border: "border-l-emerald-500", text: "text-emerald-300", dot: "bg-emerald-500" },
  warning: { border: "border-l-amber-500", text: "text-amber-300", dot: "bg-amber-500" },
  error: { border: "border-l-rose-500", text: "text-rose-300", dot: "bg-rose-500" },
  agent: { border: "border-l-slate-500", text: "text-slate-200", dot: "bg-slate-500" },
  file: { border: "border-l-slate-700", text: "text-slate-400", dot: "bg-slate-700" },
};

/** Agent name → distinct accent for chat bubbles. Falls back to a neutral slate. */
export const AGENT_STYLES: Record<
  string,
  { label: string; border: string; bubble: string; chip: string; text: string }
> = {
  planner: {
    label: "Planner",
    border: "border-emerald-500/60",
    bubble: "bg-emerald-950/40",
    chip: "bg-emerald-900/60 text-emerald-200",
    text: "text-emerald-200",
  },
  plan_reviewer: {
    label: "Plan Reviewer",
    border: "border-teal-500/60",
    bubble: "bg-teal-950/40",
    chip: "bg-teal-900/60 text-teal-200",
    text: "text-teal-200",
  },
  implementor: {
    label: "Implementor",
    border: "border-indigo-500/60",
    bubble: "bg-indigo-950/40",
    chip: "bg-indigo-900/60 text-indigo-200",
    text: "text-indigo-200",
  },
  implement_reviewer: {
    label: "Implement Reviewer",
    border: "border-amber-500/60",
    bubble: "bg-amber-950/30",
    chip: "bg-amber-900/60 text-amber-200",
    text: "text-amber-200",
  },
  publisher: {
    label: "Publisher",
    border: "border-fuchsia-500/60",
    bubble: "bg-fuchsia-950/40",
    chip: "bg-fuchsia-900/60 text-fuchsia-200",
    text: "text-fuchsia-200",
  },
};

const FALLBACK_AGENT_STYLE = {
  label: "Agent",
  border: "border-slate-600/60",
  bubble: "bg-slate-900/50",
  chip: "bg-slate-800 text-slate-200",
  text: "text-slate-200",
};

export function agentStyle(agent: string | undefined): typeof FALLBACK_AGENT_STYLE {
  if (!agent) return FALLBACK_AGENT_STYLE;
  return AGENT_STYLES[agent] ?? { ...FALLBACK_AGENT_STYLE, label: titleCaseAgent(agent) };
}

export function titleCaseAgent(agent: string): string {
  return agent
    .split(/[_\-\s]+/)
    .map((part) => (part.length > 0 ? part[0].toUpperCase() + part.slice(1) : part))
    .join(" ");
}

/** Event types that flood the feed. Gated behind filter toggles. */
export const HIGH_VOLUME_TYPES = new Set([
  "agent_text",
  "agent_tool_call",
  "file_changed",
  "ui_tests_output",
]);

export type FilterFlags = {
  agentText: boolean;
  toolCalls: boolean;
  fileChanges: boolean;
  uiTestOutput: boolean;
};

export const DEFAULT_FILTERS: FilterFlags = {
  agentText: false,
  toolCalls: false,
  fileChanges: false,
  uiTestOutput: false,
};

export function eventPassesFilters(event: HarnessEvent, filters: FilterFlags): boolean {
  if (event.type === "agent_text" && !filters.agentText) return false;
  if (event.type === "agent_tool_call" && !filters.toolCalls) return false;
  if (event.type === "file_changed" && !filters.fileChanges) return false;
  if (event.type === "ui_tests_output" && !filters.uiTestOutput) return false;
  return true;
}

function str(v: unknown): string {
  if (typeof v === "string") return v;
  if (v == null) return "";
  try {
    return JSON.stringify(v);
  } catch {
    return String(v);
  }
}

function trunc(s: string, n = 60): string {
  return s.length > n ? s.slice(0, n - 1) + "…" : s;
}

/** Maps an event → display metadata. Pure, no React. */
export function describeEvent(event: HarnessEvent): EventMeta {
  const p = event.payload || {};
  switch (event.type) {
    case "pipeline_started":
      return { category: "control", icon: "▶", label: "Pipeline started", inline: [] };
    case "pipeline_resuming":
      return {
        category: "control",
        icon: "↺",
        label: "Pipeline resuming",
        inline: [{ key: "state", value: str(p.state) }],
      };
    case "pipeline_done":
      return { category: "success", icon: "✓", label: "Pipeline done", inline: [] };
    case "state_changed":
      return {
        category: "control",
        icon: "→",
        label: "State",
        inline: [{ key: "state", value: str(p.state) }],
      };
    case "escalation":
      return {
        category: "error",
        icon: "⚠",
        label: "Escalation",
        inline: [
          { key: "phase", value: str(p.phase) },
          ...(p.error_type
            ? [{ key: "error", value: trunc(`${p.error_type}: ${str(p.error_message)}`, 80) }]
            : []),
        ],
      };
    case "phase_started":
      return {
        category: "control",
        icon: "■",
        label: phaseLabel(str(p.phase)),
        inline: [],
      };
    case "retry":
      return {
        category: "warning",
        icon: "↻",
        label: "Retry",
        inline: [{ key: "phase", value: str(p.phase) }],
      };
    case "agent_ambiguous":
      return {
        category: "warning",
        icon: "?",
        label: "Ambiguous response",
        inline: [{ key: "phase", value: str(p.phase) }],
      };
    case "agent_started":
      return { category: "agent", icon: "●", label: `${str(event.agent) || "agent"} started`, inline: [] };
    case "agent_finished":
      return {
        category: "agent",
        icon: "○",
        label: `${str(event.agent) || "agent"} finished`,
        inline: p.stop_reason ? [{ key: "stop", value: str(p.stop_reason) }] : [],
      };
    case "agent_text": {
      const text = trunc(str(p.text).replace(/\s+/g, " "), 100);
      return { category: "agent", icon: "…", label: "Agent text", inline: [{ key: "text", value: text }] };
    }
    case "agent_tool_call": {
      const tool = str(p.tool);
      const input = (p.input ?? {}) as Record<string, unknown>;
      const fp = str(input.file_path || input.notebook_path || input.path || input.command || "");
      return {
        category: "agent",
        icon: "⚙",
        label: tool || "tool",
        inline: fp ? [{ key: tool === "Bash" ? "cmd" : "path", value: trunc(fp, 80) }] : [],
      };
    }
    case "agent_blocked": {
      const tool = str(p.tool);
      const blocked = str(p.command || p.path);
      const reason = trunc(str(p.reason), 90);
      return {
        category: "error",
        icon: "⛔",
        label: "Blocked (path guard)",
        inline: [
          { key: "tool", value: tool },
          { key: tool === "Bash" ? "cmd" : "path", value: trunc(blocked, 80) },
          ...(reason ? [{ key: "reason", value: reason }] : []),
        ],
      };
    }
    case "tests_skipped":
      return {
        category: "warning",
        icon: "↷",
        label: "Tests skipped",
        inline: [
          { key: "target", value: str(p.target) },
          { key: "reason", value: trunc(str(p.reason), 80) },
        ],
      };
    case "file_changed":
      return {
        category: "file",
        icon: "✎",
        label: "File",
        inline: [
          { key: "change", value: str(p.change) },
          { key: "path", value: trunc(str(p.path), 80) },
        ],
      };
    case "iter_progress": {
      const pre = str(p.pre_sha);
      const post = str(p.post_sha);
      const auto = p.auto_committed === true;
      return {
        category: "control",
        icon: "↗",
        label: "Iteration progress",
        inline: [
          { key: "phase", value: str(p.phase) },
          { key: "sha", value: pre && post ? `${pre} → ${post}` : post || pre },
          ...(auto ? [{ key: "auto_commit", value: "true" }] : []),
        ],
      };
    }
    case "agent_stall":
      return {
        category: "error",
        icon: "⏸",
        label: "Stalled (no new commits)",
        inline: [
          { key: "phase", value: str(p.phase) },
          ...(p.head_sha ? [{ key: "head", value: str(p.head_sha) }] : []),
        ],
      };
    case "agent_usage": {
      const cost = p.total_cost_usd as number | null | undefined;
      const inT = Number(p.input_tokens ?? 0);
      const outT = Number(p.output_tokens ?? 0);
      return {
        category: "agent",
        icon: "$",
        label: "Usage",
        inline: [
          ...(cost != null ? [{ key: "cost", value: `$${cost.toFixed(4)}` }] : []),
          { key: "in", value: String(inT) },
          { key: "out", value: String(outT) },
        ],
      };
    }
    case "plan_steps": {
      const steps = (p.steps as Array<{ index: number; title: string }> | undefined) ?? [];
      return {
        category: "control",
        icon: "≡",
        label: "Plan steps",
        inline: [{ key: "count", value: String(steps.length) }],
      };
    }
    case "plan_step_progress":
      return {
        category: "control",
        icon: "▸",
        label: "Step",
        inline: [{ key: "marker", value: trunc(str(p.marker), 80) }],
      };
    case "plan_skipped":
      return {
        category: "warning",
        icon: "↷",
        label: "Planner skipped",
        inline: [
          ...(p.reason ? [{ key: "reason", value: str(p.reason) }] : []),
        ],
      };
    case "impl_skipped":
      return {
        category: "warning",
        icon: "↷",
        label: "Implementor skipped",
        inline: [
          ...(p.reason ? [{ key: "reason", value: str(p.reason) }] : []),
          ...(p.head_sha ? [{ key: "head", value: str(p.head_sha) }] : []),
        ],
      };
    case "ui_tests_started":
      return {
        category: "control",
        icon: "▶",
        label: "UI tests started",
        inline: [
          ...(p.command ? [{ key: "cmd", value: trunc(str(p.command), 80) }] : []),
        ],
      };
    case "ui_tests_finished": {
      const exit = Number(p.exit_code ?? 0);
      const dur = Number(p.duration_s ?? 0);
      return {
        category: exit === 0 ? "success" : "error",
        icon: exit === 0 ? "✓" : "✗",
        label: exit === 0 ? "UI tests passed" : "UI tests failed",
        inline: [
          { key: "exit", value: String(exit) },
          { key: "duration", value: `${dur.toFixed(1)}s` },
        ],
      };
    }
    case "ui_tests_output": {
      const line = trunc(str(p.line), 120);
      return {
        category: "agent",
        icon: "·",
        label: "UI test log",
        inline: [{ key: "line", value: line }],
      };
    }
    case "ui_verify_skipped":
      return {
        category: "warning",
        icon: "↷",
        label: "UI verification skipped",
        inline: p.reason ? [{ key: "reason", value: trunc(str(p.reason), 80) }] : [],
      };
    case "ui_verify_passed":
      return { category: "success", icon: "✓", label: "UI verification passed", inline: [] };
    case "ui_verify_failed":
      return {
        category: "error",
        icon: "✗",
        label: "UI verification failed",
        inline: [
          ...(p.reason ? [{ key: "reason", value: trunc(str(p.reason), 80) }] : []),
          ...(p.exit_code !== undefined ? [{ key: "exit", value: str(p.exit_code) }] : []),
        ],
      };
    case "ui_verify_rework_loopback":
      return {
        category: "warning",
        icon: "↺",
        label: "Loop back to implementor",
        inline: [
          ...(p.loop !== undefined && p.max_loops !== undefined
            ? [{ key: "rework", value: `${str(p.loop)}/${str(p.max_loops)}` }]
            : []),
        ],
      };
    case "agent_protocol_violation":
      return {
        category: "warning",
        icon: "!",
        label: "Protocol violation (remapped)",
        inline: [
          ...(p.phase ? [{ key: "phase", value: str(p.phase) }] : []),
          ...(p.remapped_to ? [{ key: "→", value: str(p.remapped_to) }] : []),
        ],
      };
    default:
      return { category: "agent", icon: "·", label: event.type, inline: [] };
  }
}

function phaseLabel(phase: string): string {
  switch (phase) {
    case "planning":
      return "Planning";
    case "plan_review":
      return "Plan Review";
    case "implementing":
      return "Implementing";
    case "impl_review":
      return "Impl Review";
    case "ui_verify":
      return "UI Verify";
    case "publishing":
      return "Publishing";
    default:
      return phase || "Phase";
  }
}

export { phaseLabel };

/** Render a relative time like "3s ago". Tolerates clock skew by clamping to 0. */
export function relativeTime(ts: number, now: number): string {
  const diff = Math.max(0, now - ts * 1000);
  const s = Math.floor(diff / 1000);
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  return `${d}d ago`;
}
