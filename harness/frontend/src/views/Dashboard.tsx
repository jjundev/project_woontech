import { useEffect, useState } from "react";
import { api, type WorktreeBase } from "../lib/api";
import type { HarnessEvent, TaskState, TaskStateName } from "../lib/types";

const COLUMN_LABELS: Record<string, TaskStateName[]> = {
  "To Do": ["todo", "draft"],
  Ongoing: ["planning", "plan_review", "implementing", "impl_review", "ui_verify", "publishing", "paused"],
  "Needs Attention": ["needs_attention"],
  Done: ["done"],
};

export function Dashboard({
  events,
  onSelect,
  onStart,
}: {
  events: HarnessEvent[];
  onSelect: (id: string) => void;
  onStart?: (task: TaskState, worktreeBase: WorktreeBase) => void;
}) {
  const [tasks, setTasks] = useState<TaskState[]>([]);

  const refresh = () => api.listTasks().then(setTasks).catch(console.error);

  useEffect(() => {
    refresh();
  }, []);

  useEffect(() => {
    // any state_changed / pipeline_* / file_changed event → refresh list
    if (events.length === 0) return;
    const last = events[events.length - 1];
    if (
      last.type === "state_changed" ||
      last.type === "pipeline_done" ||
      last.type === "escalation" ||
      last.type === "pipeline_started" ||
      last.type === "file_changed"
    ) {
      refresh();
    }
  }, [events]);

  return (
    <div className="h-full grid grid-cols-4 gap-3 p-4 overflow-auto">
      {Object.entries(COLUMN_LABELS).map(([label, states]) => (
        <div key={label} className="flex flex-col bg-slate-900 rounded-lg p-3 min-h-0">
          <h2 className="text-xs uppercase tracking-wide text-slate-400 mb-2">
            {label} ({tasks.filter((t) => states.includes(t.state)).length})
          </h2>
          <div className="flex-1 overflow-auto space-y-2">
            {tasks
              .filter((t) => states.includes(t.state))
              .sort((a, b) => b.updated_at - a.updated_at)
              .map((t) => (
                <TaskCard
                  key={t.id}
                  task={t}
                  onClick={() => onSelect(t.id)}
                  onStart={
                    onStart && (t.state === "todo" || t.state === "draft")
                      ? () => onStart(t, "local")
                      : undefined
                  }
                />
              ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function TaskCard({
  task,
  onClick,
  onStart,
}: {
  task: TaskState;
  onClick: () => void;
  onStart?: () => void;
}) {
  const isAttention = task.state === "needs_attention";
  return (
    <button
      onClick={onClick}
      className={`w-full text-left rounded p-3 border text-sm transition relative ${
        isAttention
          ? "bg-rose-950 border-rose-700 hover:bg-rose-900"
          : "bg-slate-800 border-slate-700 hover:bg-slate-700"
      }`}
    >
      <div className="flex items-start gap-2">
        <div className="flex-1 min-w-0">
          <div className="font-medium truncate">{task.title || task.id}</div>
          <div className="text-xs text-slate-400 mt-1 flex gap-2 items-center">
            <span>{task.state}</span>
            <span>·</span>
            <span>plan {task.plan_retries}/{task.max_plan_retries}</span>
            <span>·</span>
            <span>impl {task.impl_retries}/{task.max_impl_retries}</span>
          </div>
          {task.escalation && (
            <div className="text-xs text-rose-300 mt-1">⚠ {task.escalation}</div>
          )}
        </div>
        {onStart && (
          <span
            role="button"
            tabIndex={0}
            onClick={(e) => {
              e.stopPropagation();
              onStart();
            }}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                e.stopPropagation();
                onStart();
              }
            }}
            title="Start pipeline"
            className="shrink-0 px-2 py-1 bg-emerald-600 hover:bg-emerald-500 rounded text-xs cursor-pointer"
          >
            ▶ Start
          </span>
        )}
      </div>
    </button>
  );
}
