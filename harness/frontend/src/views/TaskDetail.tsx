import { useEffect, useState } from "react";
import { api } from "../lib/api";
import type { HarnessEvent, TaskState } from "../lib/types";

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

function TimelineItem({ event, verbose }: { event: HarnessEvent; verbose: boolean }) {
  const color =
    event.type === "escalation"
      ? "text-rose-300"
      : event.type === "pipeline_done"
      ? "text-emerald-300"
      : event.type === "retry"
      ? "text-amber-300"
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
