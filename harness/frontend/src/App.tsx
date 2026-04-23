import { useState } from "react";
import { Dashboard } from "./views/Dashboard";
import { TaskDetail } from "./views/TaskDetail";
import { NewTaskModal } from "./views/NewTaskModal";
import { useWebSocket } from "./hooks/useWebSocket";
import { api } from "./lib/api";
import type { TaskState } from "./lib/types";

export function App() {
  const [selected, setSelected] = useState<string | null>(null);
  const [showNew, setShowNew] = useState(false);
  const [startingTask, setStartingTask] = useState<TaskState | null>(null);
  const { events, connected } = useWebSocket();

  const handleRequestStart = async (task: TaskState) => {
    try {
      const r = await api.getTask(task.id);
      if (r.files.includes("spec.md")) {
        await api.startPipeline(task.id, {
          max_plan_retries: task.max_plan_retries,
          max_impl_retries: task.max_impl_retries,
        });
      } else {
        setStartingTask(task);
      }
    } catch (err) {
      alert(err instanceof Error ? err.message : String(err));
    }
  };

  return (
    <div className="h-full flex flex-col">
      <header className="border-b border-slate-800 px-6 py-3 flex items-center justify-between">
        <h1 className="text-lg font-semibold">
          iOS Harness{" "}
          <span
            className={`inline-block w-2 h-2 rounded-full ml-2 ${
              connected ? "bg-emerald-400" : "bg-rose-500"
            }`}
            title={connected ? "connected" : "disconnected"}
          />
        </h1>
        <button
          onClick={() => setShowNew(true)}
          className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-500 rounded text-sm font-medium"
        >
          + New Task
        </button>
      </header>
      <main className="flex-1 overflow-hidden">
        {selected ? (
          <TaskDetail
            taskId={selected}
            events={events.filter((e) => e.task_id === selected)}
            onBack={() => setSelected(null)}
            onStart={handleRequestStart}
          />
        ) : (
          <Dashboard
            events={events}
            onSelect={setSelected}
            onStart={handleRequestStart}
          />
        )}
      </main>
      {showNew && (
        <NewTaskModal
          onClose={() => setShowNew(false)}
          onStarted={(id) => {
            setShowNew(false);
            setSelected(id);
          }}
        />
      )}
      {startingTask && (
        <NewTaskModal
          existingTask={{ id: startingTask.id, title: startingTask.title }}
          onClose={() => setStartingTask(null)}
          onStarted={(id) => {
            setStartingTask(null);
            setSelected(id);
          }}
        />
      )}
    </div>
  );
}
