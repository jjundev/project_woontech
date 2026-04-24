import { useMemo, useState } from "react";
import type { HarnessEvent, PlanStep } from "../lib/types";

type StepStatus = "pending" | "in_progress" | "done";

interface DerivedStep extends PlanStep {
  status: StepStatus;
}

export function PlanStepsPanel({ events }: { events: HarnessEvent[] }) {
  const [collapsed, setCollapsed] = useState(false);
  const steps = useMemo(() => deriveSteps(events), [events]);
  if (steps.length === 0) return null;
  const doneCount = steps.filter((s) => s.status === "done").length;
  const activeCount = steps.filter((s) => s.status === "in_progress").length;
  return (
    <div className="border-b border-slate-800 bg-slate-950/40 text-xs">
      <button
        onClick={() => setCollapsed((v) => !v)}
        className="w-full flex items-center gap-2 px-3 py-1.5 text-left hover:bg-slate-900/50"
      >
        <span className="text-slate-300 font-semibold">Plan steps</span>
        <span className="text-slate-500">
          · {doneCount}/{steps.length} done
          {activeCount > 0 && ` · ${activeCount} in progress`}
        </span>
        <span className="flex-1" />
        <span className="text-slate-500">{collapsed ? "▸" : "▾"}</span>
      </button>
      {!collapsed && (
        <ol className="px-3 pb-2 space-y-1">
          {steps.map((step) => (
            <li key={step.index} className="flex items-baseline gap-2">
              <StatusDot status={step.status} />
              <span className="text-slate-500 w-5 shrink-0 text-right">{step.index}.</span>
              <span
                className={
                  step.status === "done"
                    ? "text-slate-500 line-through"
                    : step.status === "in_progress"
                      ? "text-indigo-200 font-medium"
                      : "text-slate-300"
                }
              >
                {step.title}
              </span>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}

function StatusDot({ status }: { status: StepStatus }) {
  if (status === "done") {
    return <span className="text-emerald-400">✓</span>;
  }
  if (status === "in_progress") {
    return (
      <span className="relative inline-flex w-2 h-2">
        <span className="absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75 animate-ping" />
        <span className="relative inline-flex rounded-full h-2 w-2 bg-indigo-400" />
      </span>
    );
  }
  return <span className="text-slate-600">○</span>;
}

function deriveSteps(events: HarnessEvent[]): DerivedStep[] {
  let base: PlanStep[] = [];
  for (let i = events.length - 1; i >= 0; i--) {
    if (events[i].type === "plan_steps") {
      const raw = (events[i].payload?.steps as PlanStep[] | undefined) ?? [];
      base = raw.map((s) => ({ index: Number(s.index), title: String(s.title) }));
      break;
    }
  }
  if (base.length === 0) return [];

  const status: StepStatus[] = base.map(() => "pending");
  let activeIndex: number | null = null;
  for (const event of events) {
    if (event.type !== "plan_step_progress") continue;
    const marker = String(event.payload?.marker ?? "");
    const matched = matchStep(base, marker);
    if (matched === null) continue;
    if (activeIndex !== null && activeIndex !== matched && status[activeIndex] === "in_progress") {
      status[activeIndex] = "done";
    }
    for (let i = 0; i < matched; i++) {
      if (status[i] === "pending") status[i] = "done";
    }
    status[matched] = "in_progress";
    activeIndex = matched;
  }

  return base.map((s, i) => ({ ...s, status: status[i] }));
}

function matchStep(steps: PlanStep[], marker: string): number | null {
  if (!marker) return null;
  const numMatch = marker.match(/^\s*(\d+)/);
  if (numMatch) {
    const n = parseInt(numMatch[1], 10);
    const idx = steps.findIndex((s) => s.index === n);
    if (idx >= 0) return idx;
  }
  const lower = marker.toLowerCase();
  let best = -1;
  let bestScore = 0;
  steps.forEach((step, i) => {
    const t = step.title.toLowerCase();
    if (lower.includes(t) || t.includes(lower)) {
      const score = Math.min(t.length, lower.length);
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
  });
  return best >= 0 ? best : null;
}
