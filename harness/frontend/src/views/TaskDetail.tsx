import { useEffect, useState } from "react";
import { api, type WorktreeStatus } from "../lib/api";
import type { HarnessEvent, TaskState, TaskStateName } from "../lib/types";

const STAGES: { key: TaskStateName; label: string }[] = [
  { key: "planning", label: "Planning" },
  { key: "plan_review", label: "Plan Review" },
  { key: "implementing", label: "Implementing" },
  { key: "impl_review", label: "Impl Review" },
  { key: "publishing", label: "Publishing" },
  { key: "done", label: "Done" },
];

export function TaskDetail({
  taskId,
  events,
  onBack,
  onStart,
}: {
  taskId: string;
  events: HarnessEvent[];
  onBack: () => void;
  onStart?: (task: TaskState) => void;
}) {
  const [task, setTask] = useState<TaskState | null>(null);
  const [files, setFiles] = useState<string[]>([]);
  const [activeFile, setActiveFile] = useState<string | null>(null);
  const [fileContent, setFileContent] = useState<string>("");
  const [verbose, setVerbose] = useState(false);

  const refresh = () =>
    api.getTask(taskId).then((r) => {
      setTask(r.state);
      setFiles(r.files);
      if (!activeFile && r.files.includes("spec.md")) setActiveFile("spec.md");
    });

  useEffect(() => {
    refresh();
  }, [taskId]);

  useEffect(() => {
    if (events.length === 0) return;
    const last = events[events.length - 1];
    if (
      last.type === "state_changed" ||
      last.type === "file_changed" ||
      last.type === "retry" ||
      last.type === "escalation" ||
      last.type === "pipeline_done"
    ) {
      refresh();
    }
  }, [events]);

  useEffect(() => {
    if (!activeFile) return;
    api
      .getFile(taskId, activeFile)
      .then((r) => setFileContent(r.content))
      .catch((e) => setFileContent(`[error] ${e.message}`));
  }, [taskId, activeFile]);

  if (!task) return <div className="p-6 text-slate-400">Loading…</div>;

  const canResume = task.state === "needs_attention";
  const canStart = task.state === "todo" || task.state === "draft";

  return (
    <div className="h-full flex flex-col">
      <div className="border-b border-slate-800 px-4 py-2 flex items-center gap-3">
        <button onClick={onBack} className="text-slate-400 hover:text-slate-100 text-sm">
          ← Back
        </button>
        <div className="font-medium">{task.title || task.id}</div>
        <div className="text-xs text-slate-400">· {task.state}</div>
        <div className="flex-1" />
        {canResume && (
          <button
            onClick={() => api.resumePipeline(taskId, {}).then(refresh)}
            className="px-3 py-1 bg-amber-600 hover:bg-amber-500 rounded text-xs"
          >
            Resume
          </button>
        )}
        {canStart && onStart && (
          <button
            onClick={() => onStart(task)}
            className="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 rounded text-xs"
          >
            ▶ Start
          </button>
        )}
        <label className="text-xs flex items-center gap-1">
          <input type="checkbox" checked={verbose} onChange={(e) => setVerbose(e.target.checked)} />
          자세히
        </label>
      </div>
      <StageIndicator state={task.state} escalation={task.escalation} />
      <div className="flex-1 grid grid-cols-12 min-h-0">
        <aside className="col-span-2 border-r border-slate-800 p-2 overflow-auto">
          <div className="text-xs uppercase text-slate-500 mb-2">Files</div>
          {files.map((f) => (
            <button
              key={f}
              onClick={() => setActiveFile(f)}
              className={`w-full text-left px-2 py-1 rounded text-sm ${
                activeFile === f ? "bg-slate-800" : "hover:bg-slate-900"
              }`}
            >
              {f}
            </button>
          ))}
        </aside>
        <section className="col-span-6 border-r border-slate-800 min-h-0 flex flex-col">
          <div className="px-3 py-2 text-xs text-slate-400 border-b border-slate-800">
            {activeFile || "(select a file)"}
          </div>
          <pre className="flex-1 overflow-auto p-3 text-xs whitespace-pre-wrap font-mono">
            {fileContent}
          </pre>
        </section>
        <section className="col-span-4 min-h-0 flex flex-col">
          <WorktreeStatusPanel taskId={taskId} state={task.state} events={events} />
          <div className="px-3 py-2 text-xs text-slate-400 border-b border-slate-800">
            Timeline ({events.length})
          </div>
          <div className="flex-1 overflow-auto p-2 space-y-1 text-xs">
            {events.map((e, i) => (
              <TimelineItem key={i} event={e} verbose={verbose} />
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

function StageIndicator({
  state,
  escalation,
}: {
  state: TaskStateName;
  escalation: string | null;
}) {
  if (state === "needs_attention") {
    return (
      <div className="px-4 py-2 bg-rose-950 border-b border-rose-800 text-rose-200 text-xs">
        ⚠ needs_attention{escalation ? ` — ${escalation}` : ""}
      </div>
    );
  }
  const currentIdx = STAGES.findIndex((s) => s.key === state);
  return (
    <div className="px-4 py-2 border-b border-slate-800 flex items-center gap-1 text-xs">
      {STAGES.map((stage, i) => {
        const done = currentIdx >= 0 && i < currentIdx;
        const active = stage.key === state;
        return (
          <div key={stage.key} className="flex items-center gap-1">
            <span
              className={`px-2 py-0.5 rounded ${
                active
                  ? "bg-indigo-600 text-white"
                  : done
                  ? "bg-emerald-700 text-emerald-100"
                  : "bg-slate-800 text-slate-400"
              }`}
            >
              {stage.label}
            </span>
            {i < STAGES.length - 1 && (
              <span className={done ? "text-emerald-600" : "text-slate-700"}>→</span>
            )}
          </div>
        );
      })}
    </div>
  );
}

const WORKTREE_ACTIVE_STATES: TaskStateName[] = [
  "planning",
  "plan_review",
  "implementing",
  "impl_review",
  "publishing",
  "needs_attention",
];

function WorktreeStatusPanel({
  taskId,
  state,
  events,
}: {
  taskId: string;
  state: TaskStateName;
  events: HarnessEvent[];
}) {
  const [status, setStatus] = useState<WorktreeStatus | null>(null);
  const [error, setError] = useState<string | null>(null);
  const active = WORKTREE_ACTIVE_STATES.includes(state);

  useEffect(() => {
    if (!active) {
      setStatus(null);
      return;
    }
    let cancelled = false;
    const load = () =>
      api
        .getWorktreeStatus(taskId)
        .then((r) => {
          if (!cancelled) {
            setStatus(r);
            setError(null);
          }
        })
        .catch((e) => {
          if (!cancelled) setError(e instanceof Error ? e.message : String(e));
        });
    load();
    const id = setInterval(load, 5000);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [taskId, active]);

  useEffect(() => {
    if (!active || events.length === 0) return;
    const last = events[events.length - 1];
    if (last.type === "file_changed" || last.type === "agent_blocked") {
      api
        .getWorktreeStatus(taskId)
        .then(setStatus)
        .catch(() => {});
    }
  }, [events, active, taskId]);

  if (!active) return null;

  return (
    <div className="border-b border-slate-800 p-2 text-xs">
      <div className="flex items-center gap-2 mb-1">
        <span className="uppercase text-slate-500">Worktree</span>
        {status?.branch && <span className="text-slate-400">· {status.branch}</span>}
        {status && <span className="text-slate-400">· +{status.commits_ahead} commits</span>}
      </div>
      {error && <div className="text-rose-400">[error] {error}</div>}
      {status && !status.exists && <div className="text-slate-500">not created yet</div>}
      {status?.exists && status.files.length === 0 && (
        <div className="text-slate-500">clean</div>
      )}
      {status?.exists && status.files.length > 0 && (
        <ul className="space-y-0.5 max-h-32 overflow-auto">
          {status.files.map((f, i) => (
            <li key={i} className="flex gap-2">
              <span className="text-slate-500 w-16 shrink-0">{f.change}</span>
              <span className="truncate font-mono">{f.path}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function TimelineItem({ event, verbose }: { event: HarnessEvent; verbose: boolean }) {
  const color =
    event.type === "escalation"
      ? "text-rose-300"
      : event.type === "pipeline_done"
      ? "text-emerald-300"
      : event.type === "retry"
      ? "text-amber-300"
      : event.type === "agent_blocked"
      ? "text-rose-300"
      : event.type === "tests_skipped"
      ? "text-amber-200"
      : "text-slate-300";
  return (
    <div className={`rounded border border-slate-800 p-2 ${color}`}>
      <div className="flex gap-2 items-center">
        <span className="font-mono">{event.type}</span>
        {event.agent && <span className="text-slate-500">· {event.agent}</span>}
        {event.iteration !== undefined && (
          <span className="text-slate-500">· iter {event.iteration}</span>
        )}
      </div>
      {verbose && Object.keys(event.payload).length > 0 && (
        <pre className="text-[10px] text-slate-400 mt-1 whitespace-pre-wrap break-all">
          {JSON.stringify(event.payload, null, 2)}
        </pre>
      )}
    </div>
  );
}
