import { useEffect, useRef, useState } from "react";
import { api } from "../lib/api";

type Message = { role: "user" | "spector"; text: string };

export function NewTaskModal({
  onClose,
  onStarted,
  existingTask,
}: {
  onClose: () => void;
  onStarted: (taskId: string) => void;
  existingTask?: { id: string; title: string };
}) {
  const [step, setStep] = useState<"title" | "chat" | "start">(
    existingTask ? "chat" : "title",
  );
  const [title, setTitle] = useState(existingTask?.title ?? "");
  const [taskId, setTaskId] = useState<string | null>(existingTask?.id ?? null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [specReady, setSpecReady] = useState(false);
  const [maxPlan, setMaxPlan] = useState(3);
  const [maxImpl, setMaxImpl] = useState(3);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight });
  }, [messages]);

  useEffect(() => {
    if (!existingTask) return;
    let cancelled = false;
    (async () => {
      setBusy(true);
      try {
        const r = await api.spectorMessage(
          existingTask.id,
          `Resuming spec drafting for existing task "${existingTask.title}". If spec.md already captures the intent, respond with SPEC_CONFIRMED; otherwise continue clarifying.`,
        );
        if (cancelled) return;
        setMessages([{ role: "spector", text: r.reply }]);
        setSpecReady(r.confirmed);
      } catch (err) {
        if (cancelled) return;
        setMessages([{ role: "spector", text: `[error] ${errMsg(err)}` }]);
      } finally {
        if (!cancelled) setBusy(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [existingTask]);

  const errMsg = (err: unknown): string =>
    err instanceof Error ? err.message : String(err);

  const createTask = async () => {
    if (!title.trim()) return;
    setBusy(true);
    try {
      const t = await api.createTask(title.trim());
      setTaskId(t.id);
      setStep("chat");
      try {
        const r = await api.spectorMessage(
          t.id,
          `User wants to build: "${title.trim()}". Ask clarifying questions to produce spec.md.`,
        );
        setMessages([{ role: "spector", text: r.reply }]);
        setSpecReady(r.confirmed);
      } catch (err) {
        setMessages([
          { role: "spector", text: `[error] ${errMsg(err)}` },
        ]);
      }
    } finally {
      setBusy(false);
    }
  };

  const send = async () => {
    if (!input.trim() || !taskId || busy) return;
    const text = input.trim();
    setInput("");
    setMessages((m) => [...m, { role: "user", text }]);
    setBusy(true);
    try {
      const r = await api.spectorMessage(taskId, text);
      setMessages((m) => [...m, { role: "spector", text: r.reply }]);
      setSpecReady(r.confirmed);
    } catch (err) {
      setMessages((m) => [...m, { role: "spector", text: `[error] ${errMsg(err)}` }]);
    } finally {
      setBusy(false);
    }
  };

  const startPipeline = async () => {
    if (!taskId) return;
    await api.startPipeline(taskId, {
      max_plan_retries: maxPlan,
      max_impl_retries: maxImpl,
    });
    onStarted(taskId);
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center p-4 z-50">
      <div className="bg-slate-900 rounded-lg w-[720px] max-w-full h-[80vh] flex flex-col border border-slate-700">
        <div className="border-b border-slate-800 px-4 py-3 flex justify-between items-center">
          <h2 className="font-semibold">New Task</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-100">
            ✕
          </button>
        </div>
        {step === "title" && (
          <div className="p-6 flex-1 flex flex-col justify-center gap-3">
            <label className="text-sm">Task title</label>
            <input
              autoFocus
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Add dark mode toggle to Settings"
              className="bg-slate-800 border border-slate-700 rounded px-3 py-2 text-sm"
              onKeyDown={(e) => e.key === "Enter" && createTask()}
            />
            <button
              disabled={busy || !title.trim()}
              onClick={createTask}
              className="self-end px-4 py-2 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-40 rounded text-sm"
            >
              {busy ? "Creating…" : "Next →"}
            </button>
          </div>
        )}
        {step === "chat" && (
          <>
            <div ref={scrollRef} className="flex-1 overflow-auto p-4 space-y-3">
              {messages.map((m, i) => (
                <div
                  key={i}
                  className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}
                >
                  <div
                    className={`max-w-[80%] rounded px-3 py-2 text-sm whitespace-pre-wrap ${
                      m.role === "user" ? "bg-indigo-600" : "bg-slate-800"
                    }`}
                  >
                    {m.text}
                  </div>
                </div>
              ))}
              {busy && <div className="text-xs text-slate-500">spector is thinking…</div>}
            </div>
            <div className="border-t border-slate-800 p-3 flex gap-2 items-end">
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
                    e.preventDefault();
                    send();
                  }
                }}
                rows={2}
                placeholder="Reply to spector… (⌘/Ctrl+Enter to send)"
                className="flex-1 bg-slate-800 border border-slate-700 rounded px-3 py-2 text-sm"
              />
              <button
                disabled={busy || !input.trim()}
                onClick={send}
                className="px-4 py-2 bg-slate-700 hover:bg-slate-600 disabled:opacity-40 rounded text-sm"
              >
                Send
              </button>
              <button
                disabled={!specReady}
                onClick={() => setStep("start")}
                className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-40 rounded text-sm"
                title={specReady ? "spec confirmed" : "wait for SPEC_CONFIRMED from spector"}
              >
                Confirm spec →
              </button>
            </div>
          </>
        )}
        {step === "start" && (
          <div className="p-6 flex-1 flex flex-col gap-4">
            <div>
              <div className="text-sm text-slate-400">
                Spec has been confirmed and saved to the task folder. Configure pipeline retries and start.
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <label className="text-sm">
                Max plan retries
                <input
                  type="number"
                  min={0}
                  max={10}
                  value={maxPlan}
                  onChange={(e) => setMaxPlan(parseInt(e.target.value, 10))}
                  className="w-full mt-1 bg-slate-800 border border-slate-700 rounded px-3 py-2"
                />
              </label>
              <label className="text-sm">
                Max impl retries
                <input
                  type="number"
                  min={0}
                  max={10}
                  value={maxImpl}
                  onChange={(e) => setMaxImpl(parseInt(e.target.value, 10))}
                  className="w-full mt-1 bg-slate-800 border border-slate-700 rounded px-3 py-2"
                />
              </label>
            </div>
            <div className="flex-1" />
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setStep("chat")}
                className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded text-sm"
              >
                ← Back to chat
              </button>
              <button
                onClick={startPipeline}
                className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded text-sm"
              >
                Start pipeline
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
