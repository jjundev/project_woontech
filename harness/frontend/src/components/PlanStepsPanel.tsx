import { useMemo, useState } from "react";
import type { HarnessEvent, PlanStep } from "../lib/types";

type StepStatus = "pending" | "in_progress" | "done";

interface DerivedStep extends PlanStep {
  status: StepStatus;
}

export function PlanStepsPanel({
  events,
  initialSteps,
}: {
  events: HarnessEvent[];
  initialSteps: PlanStep[];
}) {
  const [collapsed, setCollapsed] = useState(false);
  const steps = useMemo(() => deriveSteps(events, initialSteps), [events, initialSteps]);
  if (steps.length === 0) return null;
  const doneCount = steps.filter((s) => s.status === "done").length;
  const activeCount = steps.filter((s) => s.status === "in_progress").length;
  return (
    <div className="border-b border-slate-800 bg-slate-950/40 text-xs shrink-0 flex flex-col min-h-0 max-h-[35vh]">
      <button
        onClick={() => setCollapsed((v) => !v)}
        className="w-full flex items-center gap-2 px-3 py-1.5 text-left hover:bg-slate-900/50 shrink-0"
      >
        <span className="text-slate-300 font-semibold">Plan steps</span>
        <span className="text-slate-500 min-w-0">
          · {doneCount}/{steps.length} done
          {activeCount > 0 && ` · ${activeCount} in progress`}
        </span>
        <span className="flex-1" />
        <span className="text-slate-500">{collapsed ? "▸" : "▾"}</span>
      </button>
      {!collapsed && (
        <ol className="px-3 pb-2 space-y-1 overflow-auto min-h-0">
          {steps.map((step) => (
            <li key={step.index} className="flex items-start gap-2">
              <span className="w-3 shrink-0 pt-0.5">
                <StatusDot status={step.status} />
              </span>
              <span className="text-slate-500 w-5 shrink-0 text-right">{step.index}.</span>
              <span
                className={
                  step.status === "done"
                    ? "text-slate-500 line-through break-words min-w-0"
                    : step.status === "in_progress"
                      ? "text-indigo-200 font-medium break-words min-w-0"
                      : "text-slate-300 break-words min-w-0"
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

function deriveSteps(events: HarnessEvent[], initialSteps: PlanStep[]): DerivedStep[] {
  const currentRun = findCurrentRun(events);
  const latestRunSteps = latestPlanStepsForRun(events, currentRun);
  const base = latestRunSteps ?? normalizeSteps(initialSteps);
  if (base.length === 0) return [];

  const status: StepStatus[] = base.map(() => "pending");
  let activeIndex: number | null = null;
  let reachedTerminal = false;

  // pre-resume baseline: 이전 run(들)의 진행 상태를 기준점으로 복원
  const isResume = events[currentRun.startIndex]?.type === "pipeline_resuming";
  if (isResume) {
    let prevActiveIndex: number | null = null;
    for (let i = 0; i < currentRun.startIndex; i++) {
      const event = events[i];
      if (event.type !== "plan_step_progress") continue;
      if (event.agent && event.agent !== "implementor") continue;
      const marker = String(event.payload?.marker ?? "");
      const matched = matchStep(base, marker);
      if (matched === null) continue;
      if (prevActiveIndex !== null && prevActiveIndex !== matched) {
        status[prevActiveIndex] = "done";
      }
      for (let j = 0; j < matched; j++) {
        if (status[j] === "pending") status[j] = "done";
      }
      status[matched] = "in_progress";
      prevActiveIndex = matched;
    }
    if (prevActiveIndex !== null && status[prevActiveIndex] === "in_progress") {
      status[prevActiveIndex] = "done";
    }
  }

  events.forEach((event, index) => {
    if (!belongsToCurrentRun(event, index, currentRun)) return;
    if (event.type !== "plan_step_progress") return;
    if (event.agent && event.agent !== "implementor") return;
    const marker = String(event.payload?.marker ?? "");
    const matched = matchStep(base, marker);
    if (matched === null) return;
    if (activeIndex !== null && activeIndex !== matched && status[activeIndex] === "in_progress") {
      status[activeIndex] = "done";
    }
    for (let i = 0; i < matched; i++) {
      if (status[i] === "pending") status[i] = "done";
    }
    status[matched] = "in_progress";
    activeIndex = matched;
  });

  events.forEach((event, index) => {
    if (!belongsToCurrentRun(event, index, currentRun)) return;
    if (isTerminalProgressEvent(event)) reachedTerminal = true;
  });

  if (reachedTerminal && activeIndex !== null) {
    for (let i = 0; i <= activeIndex; i++) {
      status[i] = "done";
    }
  }

  return base.map((s, i) => ({ ...s, status: status[i] }));
}

type RunBoundary = {
  runId: string | null;
  startIndex: number;
};

function findCurrentRun(events: HarnessEvent[]): RunBoundary {
  for (let i = events.length - 1; i >= 0; i--) {
    const event = events[i];
    if (event.type === "pipeline_started" || event.type === "pipeline_resuming") {
      return {
        runId: typeof event.run_id === "string" && event.run_id.length > 0 ? event.run_id : null,
        startIndex: i,
      };
    }
  }
  return { runId: null, startIndex: 0 };
}

function belongsToCurrentRun(event: HarnessEvent, index: number, currentRun: RunBoundary): boolean {
  if (currentRun.runId) return event.run_id === currentRun.runId;
  return index >= currentRun.startIndex;
}

function latestPlanStepsForRun(
  events: HarnessEvent[],
  currentRun: RunBoundary,
): PlanStep[] | null {
  for (let i = events.length - 1; i >= 0; i--) {
    const event = events[i];
    if (event.type !== "plan_steps") continue;
    if (!belongsToCurrentRun(event, i, currentRun)) continue;
    const raw = (event.payload?.steps as PlanStep[] | undefined) ?? [];
    return normalizeSteps(raw);
  }
  return null;
}

function normalizeSteps(raw: PlanStep[]): PlanStep[] {
  return raw
    .map((s) => ({ index: Number(s.index), title: String(s.title) }))
    .filter((s) => Number.isFinite(s.index) && s.title.length > 0);
}

function isTerminalProgressEvent(event: HarnessEvent): boolean {
  if (event.type === "pipeline_done") return true;
  if (event.type !== "phase_started") return false;
  const phase = String(event.payload?.phase ?? "");
  return phase === "impl_review" || phase === "ui_verify" || phase === "publishing";
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
