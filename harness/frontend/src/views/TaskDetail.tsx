import { useEffect, useMemo, useRef, useState } from "react";
import { api, type WorktreeBase, type WorktreeStatus } from "../lib/api";
import type { HarnessEvent, PlanStep, TaskState, TaskStateName } from "../lib/types";
import {
  CATEGORY_STYLES,
  DEFAULT_FILTERS,
  describeEvent,
  eventPassesFilters,
  phaseLabel,
  relativeTime,
  type FilterFlags,
} from "../lib/timeline";
import { ChatTimeline } from "../components/ChatTimeline";
import { PlanStepsPanel } from "../components/PlanStepsPanel";
import { CostDialog } from "../components/CostDialog";

const STAGES: { key: TaskStateName; label: string }[] = [
  { key: "planning", label: "Planning" },
  { key: "plan_review", label: "Plan Review" },
  { key: "implementing", label: "Implementing" },
  { key: "impl_review", label: "Impl Review" },
  { key: "publishing", label: "Publishing" },
  { key: "done", label: "Done" },
];

type Tab = { source: "task" | "worktree"; path: string };

const tabKey = (t: Tab): string => `${t.source}:${t.path}`;

const PAUSE_STATES: TaskStateName[] = [
  "planning",
  "plan_review",
  "implementing",
  "impl_review",
  "publishing",
];

const PANE_WIDTH_STORAGE_KEY = "harness.taskDetail.paneWidths.v1";
const MIN_PANE_PX = 180;
const MIN_CENTER_PX = 240;
const DEFAULT_LEFT_PX = 260;
const DEFAULT_RIGHT_PX = 360;

type PaneWidths = { left: number; right: number };

function loadPaneWidths(): PaneWidths {
  if (typeof localStorage === "undefined") {
    return { left: DEFAULT_LEFT_PX, right: DEFAULT_RIGHT_PX };
  }
  try {
    const raw = localStorage.getItem(PANE_WIDTH_STORAGE_KEY);
    if (!raw) return { left: DEFAULT_LEFT_PX, right: DEFAULT_RIGHT_PX };
    const parsed = JSON.parse(raw) as Partial<PaneWidths>;
    return {
      left: Math.max(MIN_PANE_PX, parsed.left ?? DEFAULT_LEFT_PX),
      right: Math.max(MIN_PANE_PX, parsed.right ?? DEFAULT_RIGHT_PX),
    };
  } catch {
    return { left: DEFAULT_LEFT_PX, right: DEFAULT_RIGHT_PX };
  }
}

function savePaneWidths(w: PaneWidths): void {
  if (typeof localStorage === "undefined") return;
  try {
    localStorage.setItem(PANE_WIDTH_STORAGE_KEY, JSON.stringify(w));
  } catch {}
}

export function TaskDetail({
  taskId,
  events,
  onBack,
  onStart,
}: {
  taskId: string;
  events: HarnessEvent[];
  onBack: () => void;
  onStart?: (task: TaskState, worktreeBase: WorktreeBase) => void;
}) {
  const [task, setTask] = useState<TaskState | null>(null);
  const [files, setFiles] = useState<string[]>([]);
  const [planSteps, setPlanSteps] = useState<PlanStep[]>([]);
  const [worktreeBase, setWorktreeBase] = useState<WorktreeBase>("local");

  const [tabs, setTabs] = useState<Tab[]>([]);
  const [activeKey, setActiveKey] = useState<string | null>(null);
  const [contents, setContents] = useState<Record<string, string>>({});
  const defaultOpenedRef = useRef(false);

  const [paneWidths, setPaneWidths] = useState<PaneWidths>(loadPaneWidths);
  const panesContainerRef = useRef<HTMLDivElement | null>(null);
  const [costOpen, setCostOpen] = useState(false);
  const taskEvents = useMemo(
    () => events.filter((e) => !e.task_id || e.task_id === taskId),
    [events, taskId],
  );

  useEffect(() => {
    savePaneWidths(paneWidths);
  }, [paneWidths]);

  const dragPane = (edge: "left" | "right") => (dx: number) => {
    setPaneWidths((prev) => {
      const container = panesContainerRef.current;
      const containerWidth = container?.clientWidth ?? 0;
      const maxPane = Math.max(
        MIN_PANE_PX,
        containerWidth - MIN_CENTER_PX - MIN_PANE_PX,
      );
      if (edge === "left") {
        const next = Math.max(MIN_PANE_PX, Math.min(maxPane, prev.left + dx));
        return { ...prev, left: next };
      }
      const next = Math.max(MIN_PANE_PX, Math.min(maxPane, prev.right - dx));
      return { ...prev, right: next };
    });
  };

  const openTab = (tab: Tab) => {
    const key = tabKey(tab);
    setTabs((prev) => (prev.some((t) => tabKey(t) === key) ? prev : [...prev, tab]));
    setActiveKey(key);
    const fetcher =
      tab.source === "task"
        ? api.getFile(taskId, tab.path).then((r) => r.content)
        : api.getWorktreeFile(taskId, tab.path).then((r) => r.content);
    fetcher
      .then((c) => setContents((prev) => ({ ...prev, [key]: c })))
      .catch((e: unknown) =>
        setContents((prev) => ({
          ...prev,
          [key]: `[error] ${e instanceof Error ? e.message : String(e)}`,
        })),
      );
  };

  const closeTab = (key: string) => {
    setTabs((prev) => {
      const idx = prev.findIndex((t) => tabKey(t) === key);
      if (idx < 0) return prev;
      const next = [...prev.slice(0, idx), ...prev.slice(idx + 1)];
      if (activeKey === key) {
        const fallback = next[idx] ?? next[idx - 1] ?? null;
        setActiveKey(fallback ? tabKey(fallback) : null);
      }
      return next;
    });
    setContents((prev) => {
      if (!(key in prev)) return prev;
      const { [key]: _omit, ...rest } = prev;
      return rest;
    });
  };

  const refresh = () =>
    Promise.all([api.getTask(taskId), api.getPlanSteps(taskId)]).then(([r, plan]) => {
      setTask(r.state);
      setFiles(r.files);
      setPlanSteps(plan.steps);
      if (!defaultOpenedRef.current && r.files.includes("spec.md")) {
        defaultOpenedRef.current = true;
        openTab({ source: "task", path: "spec.md" });
      }
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

  if (!task) return <div className="p-6 text-slate-400">Loading…</div>;

  const canResume = task.state === "needs_attention" || task.state === "paused";
  const canStart = task.state === "todo" || task.state === "draft";
  const canPause = PAUSE_STATES.includes(task.state);
  const canResumeFromReview =
    canResume &&
    (task.paused_from === "impl_review" ||
      (task.state === "needs_attention" &&
        (task.escalation ?? "").toLowerCase().includes("impl")));

  return (
    <div className="h-full flex flex-col">
      <div className="border-b border-slate-800 px-4 py-2 flex items-center gap-3">
        <button onClick={onBack} className="text-slate-400 hover:text-slate-100 text-sm">
          ← Back
        </button>
        <div className="font-medium">{task.title || task.id}</div>
        <div className="text-xs text-slate-400">· {task.state}</div>
        <div className="flex-1" />
        <button
          onClick={() => setCostOpen(true)}
          className="px-3 py-1 bg-slate-800 hover:bg-slate-700 rounded text-xs text-emerald-300"
          title="Token usage and cost for this task"
        >
          $ Cost
        </button>
        {canPause && (
          <button
            onClick={() =>
              api
                .pausePipeline(taskId)
                .then(refresh)
                .catch((e: unknown) =>
                  alert(e instanceof Error ? e.message : String(e)),
                )
            }
            className="px-3 py-1 bg-slate-700 hover:bg-slate-600 rounded text-xs"
          >
            ⏸ Pause
          </button>
        )}
        {canResume && (
          <button
            onClick={() => api.resumePipeline(taskId, {}).then(refresh)}
            className="px-3 py-1 bg-amber-600 hover:bg-amber-500 rounded text-xs"
          >
            Resume
          </button>
        )}
        {canResumeFromReview && (
          <button
            onClick={() =>
              api
                .resumePipeline(taskId, { resume_from: "impl_review" })
                .then(refresh)
                .catch((e: unknown) =>
                  alert(e instanceof Error ? e.message : String(e)),
                )
            }
            title="implementor 를 건너뛰고 현재 워크트리 코드로 리뷰부터 재개"
            className="px-3 py-1 bg-amber-700 hover:bg-amber-600 rounded text-xs"
          >
            Resume from Review
          </button>
        )}
        {canStart && onStart && (
          <>
            <select
              value={worktreeBase}
              onChange={(e) => setWorktreeBase(e.target.value as WorktreeBase)}
              className="px-2 py-1 bg-slate-800 border border-slate-700 rounded text-xs"
              title="Worktree base ref"
            >
              <option value="local">Local main</option>
              <option value="remote">Remote origin/main</option>
            </select>
            <button
              onClick={() => onStart(task, worktreeBase)}
              className="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 rounded text-xs"
            >
              ▶ Start
            </button>
          </>
        )}
      </div>
      <StageIndicator
        state={task.state}
        escalation={task.escalation}
        pausedFrom={task.paused_from}
      />
      <div ref={panesContainerRef} className="flex-1 flex min-h-0">
        <aside
          style={{ width: paneWidths.left }}
          className="border-r border-slate-800 flex flex-col min-h-0 shrink-0"
        >
          <div className="p-2 overflow-auto flex-1 min-h-0">
            <div className="text-xs uppercase text-slate-500 mb-2">Files</div>
            {files.map((f) => {
              const key = tabKey({ source: "task", path: f });
              return (
                <button
                  key={f}
                  onClick={() => openTab({ source: "task", path: f })}
                  className={`w-full text-left px-2 py-1 rounded text-sm truncate ${
                    activeKey === key ? "bg-slate-800" : "hover:bg-slate-900"
                  }`}
                >
                  {f}
                </button>
              );
            })}
          </div>
          <WorktreeStatusPanel
            taskId={taskId}
            state={task.state}
            events={events}
            activeKey={activeKey}
            onOpenFile={(path) => openTab({ source: "worktree", path })}
          />
        </aside>
        <PaneResizer onDrag={dragPane("left")} />
        <section className="flex-1 min-h-0 flex flex-col min-w-0">
          <TabBar tabs={tabs} activeKey={activeKey} onSelect={setActiveKey} onClose={closeTab} />
          <pre className="flex-1 overflow-auto p-3 text-xs whitespace-pre-wrap font-mono">
            {activeKey
              ? contents[activeKey] ?? "loading…"
              : "(select a file)"}
          </pre>
        </section>
        <PaneResizer onDrag={dragPane("right")} />
        <section
          style={{ width: paneWidths.right }}
          className="min-h-0 flex flex-col shrink-0"
        >
          <RightPanel events={events} taskEvents={taskEvents} initialPlanSteps={planSteps} />
        </section>
      </div>
      {costOpen && (
        <CostDialog events={taskEvents} onClose={() => setCostOpen(false)} />
      )}
    </div>
  );
}

const RIGHT_TAB_STORAGE_KEY = "harness.taskDetail.rightTab.v1";

function loadRightTab(): "chat" | "events" {
  if (typeof localStorage === "undefined") return "chat";
  const saved = localStorage.getItem(RIGHT_TAB_STORAGE_KEY);
  return saved === "events" ? "events" : "chat";
}

function RightPanel({
  events,
  taskEvents,
  initialPlanSteps,
}: {
  events: HarnessEvent[];
  taskEvents: HarnessEvent[];
  initialPlanSteps: PlanStep[];
}) {
  const [tab, setTab] = useState<"chat" | "events">(loadRightTab);
  useEffect(() => {
    if (typeof localStorage === "undefined") return;
    try {
      localStorage.setItem(RIGHT_TAB_STORAGE_KEY, tab);
    } catch {}
  }, [tab]);
  return (
    <>
      <div className="px-2 py-1 border-b border-slate-800 flex items-center gap-1 text-xs">
        <TabButton active={tab === "chat"} onClick={() => setTab("chat")}>
          Chat
        </TabButton>
        <TabButton active={tab === "events"} onClick={() => setTab("events")}>
          Events
        </TabButton>
      </div>
      {tab === "chat" ? (
        <>
          <PlanStepsPanel events={taskEvents} initialSteps={initialPlanSteps} />
          <ChatTimeline events={taskEvents} />
        </>
      ) : (
        <TimelinePanel events={events} />
      )}
    </>
  );
}

function TabButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className={`px-2 py-0.5 rounded ${
        active ? "bg-slate-800 text-slate-100" : "text-slate-500 hover:text-slate-300"
      }`}
    >
      {children}
    </button>
  );
}

function TabBar({
  tabs,
  activeKey,
  onSelect,
  onClose,
}: {
  tabs: Tab[];
  activeKey: string | null;
  onSelect: (key: string) => void;
  onClose: (key: string) => void;
}) {
  if (tabs.length === 0) {
    return (
      <div className="px-3 py-2 text-xs text-slate-500 border-b border-slate-800">
        (select a file)
      </div>
    );
  }
  return (
    <div className="flex items-stretch border-b border-slate-800 overflow-x-auto">
      {tabs.map((t) => {
        const key = tabKey(t);
        const active = key === activeKey;
        return (
          <div
            key={key}
            onClick={() => onSelect(key)}
            className={`flex items-center gap-1 px-3 py-1.5 text-xs border-r border-slate-800 shrink-0 cursor-pointer ${
              active
                ? "bg-slate-800 text-slate-100"
                : "text-slate-400 hover:bg-slate-900"
            }`}
            title={`${t.source}: ${t.path}`}
          >
            <span className="font-mono">
              {t.source === "worktree" ? "⎇ " : ""}
              {t.path}
            </span>
            <button
              onClick={(e) => {
                e.stopPropagation();
                onClose(key);
              }}
              className="text-slate-500 hover:text-slate-200 ml-1"
              aria-label="Close tab"
            >
              ×
            </button>
          </div>
        );
      })}
    </div>
  );
}

function PaneResizer({ onDrag }: { onDrag: (dx: number) => void }) {
  const dragging = useRef(false);

  const onMouseDown = (e: React.MouseEvent) => {
    e.preventDefault();
    dragging.current = true;
    let lastX = e.clientX;

    const onMove = (ev: MouseEvent) => {
      if (!dragging.current) return;
      const dx = ev.clientX - lastX;
      lastX = ev.clientX;
      if (dx !== 0) onDrag(dx);
    };
    const onUp = () => {
      dragging.current = false;
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
      document.body.style.cursor = "";
      document.body.style.userSelect = "";
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    document.body.style.cursor = "col-resize";
    document.body.style.userSelect = "none";
  };

  return (
    <div
      role="separator"
      aria-orientation="vertical"
      onMouseDown={onMouseDown}
      className="w-1 shrink-0 bg-slate-800 hover:bg-slate-600 cursor-col-resize transition-colors"
    />
  );
}

function StageIndicator({
  state,
  escalation,
  pausedFrom,
}: {
  state: TaskStateName;
  escalation: string | null;
  pausedFrom: TaskStateName | null;
}) {
  if (state === "needs_attention") {
    return (
      <div className="px-4 py-2 bg-rose-950 border-b border-rose-800 text-rose-200 text-xs">
        ⚠ needs_attention{escalation ? ` — ${escalation}` : ""}
      </div>
    );
  }
  if (state === "paused") {
    return (
      <div className="px-4 py-2 bg-slate-900 border-b border-slate-800 text-slate-300 text-xs">
        ⏸ paused{pausedFrom ? ` from ${pausedFrom}` : ""}
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
  "paused",
];

function WorktreeStatusPanel({
  taskId,
  state,
  events,
  activeKey,
  onOpenFile,
}: {
  taskId: string;
  state: TaskStateName;
  events: HarnessEvent[];
  activeKey: string | null;
  onOpenFile: (path: string) => void;
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
    <div className="h-64 border-t border-slate-800 p-2 text-xs flex flex-col min-h-0">
      <div className="flex items-center gap-2 mb-1 shrink-0">
        <span className="uppercase text-slate-500">Worktree</span>
        {status?.branch && <span className="text-slate-400 truncate">· {status.branch}</span>}
        {status && <span className="text-slate-400">· +{status.commits_ahead}</span>}
      </div>
      {error && <div className="text-rose-400 shrink-0">[error] {error}</div>}
      {status && !status.exists && <div className="text-slate-500">not created yet</div>}
      {status?.exists && status.files.length === 0 && (
        <div className="text-slate-500">clean</div>
      )}
      {status?.exists && status.files.length > 0 && (
        <ul className="space-y-0.5 flex-1 overflow-auto min-h-0">
          {status.files.map((f, i) => {
            const key = `worktree:${f.path}`;
            const isActive = activeKey === key;
            const isRename = f.path.includes(" -> ");
            return (
              <li key={i}>
                <button
                  onClick={() => {
                    if (isRename) return;
                    onOpenFile(f.path);
                  }}
                  disabled={isRename}
                  className={`w-full flex gap-2 px-1 py-0.5 rounded text-left ${
                    isActive
                      ? "bg-slate-800"
                      : isRename
                      ? "opacity-60 cursor-default"
                      : "hover:bg-slate-900"
                  }`}
                  title={f.path}
                >
                  <span className="text-slate-500 w-16 shrink-0">{f.change}</span>
                  <span className="truncate font-mono">{f.path}</span>
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

const FILTER_STORAGE_KEY = "harness.timeline.filters.v1";

function loadFilters(): FilterFlags {
  if (typeof localStorage === "undefined") return DEFAULT_FILTERS;
  try {
    const raw = localStorage.getItem(FILTER_STORAGE_KEY);
    if (!raw) return DEFAULT_FILTERS;
    return { ...DEFAULT_FILTERS, ...(JSON.parse(raw) as Partial<FilterFlags>) };
  } catch {
    return DEFAULT_FILTERS;
  }
}

function saveFilters(f: FilterFlags): void {
  if (typeof localStorage === "undefined") return;
  try {
    localStorage.setItem(FILTER_STORAGE_KEY, JSON.stringify(f));
  } catch {}
}

function TimelinePanel({ events }: { events: HarnessEvent[] }) {
  const [filters, setFilters] = useState<FilterFlags>(loadFilters);
  const [now, setNow] = useState(() => Date.now());
  const containerRef = useRef<HTMLDivElement | null>(null);
  const stickToBottomRef = useRef(true);

  useEffect(() => {
    saveFilters(filters);
  }, [filters]);

  // Tick once a second for relative-time labels.
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  const visibleEvents = useMemo(
    () => events.filter((e) => eventPassesFilters(e, filters)),
    [events, filters],
  );

  // Auto-scroll to bottom on new events, unless the user has scrolled up.
  useEffect(() => {
    const el = containerRef.current;
    if (!el || !stickToBottomRef.current) return;
    el.scrollTop = el.scrollHeight;
  }, [visibleEvents.length]);

  const onScroll = () => {
    const el = containerRef.current;
    if (!el) return;
    const distance = el.scrollHeight - (el.scrollTop + el.clientHeight);
    stickToBottomRef.current = distance < 16;
  };

  const setFlag = (key: keyof FilterFlags) => (checked: boolean) =>
    setFilters((prev) => ({ ...prev, [key]: checked }));

  return (
    <>
      <div className="px-3 py-1.5 text-xs text-slate-400 border-b border-slate-800 flex items-center justify-between gap-2">
        <span>Timeline · {visibleEvents.length}/{events.length}</span>
        <div className="flex items-center gap-2">
          <FilterToggle label="text" checked={filters.agentText} onChange={setFlag("agentText")} />
          <FilterToggle label="tools" checked={filters.toolCalls} onChange={setFlag("toolCalls")} />
          <FilterToggle label="files" checked={filters.fileChanges} onChange={setFlag("fileChanges")} />
        </div>
      </div>
      <div
        ref={containerRef}
        onScroll={onScroll}
        className="flex-1 overflow-auto p-2 space-y-1 text-xs"
      >
        {visibleEvents.map((e, i) => (
          <TimelineItem key={`${e.ts}-${i}`} event={e} now={now} />
        ))}
      </div>
    </>
  );
}

function FilterToggle({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}) {
  return (
    <label
      className={`flex items-center gap-1 px-1.5 py-0.5 rounded cursor-pointer select-none ${
        checked ? "bg-slate-800 text-slate-100" : "text-slate-500 hover:text-slate-300"
      }`}
    >
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="hidden"
      />
      {label}
    </label>
  );
}

function TimelineItem({ event, now }: { event: HarnessEvent; now: number }) {
  const [expanded, setExpanded] = useState(false);

  // phase_started is rendered as a section divider instead of a card.
  if (event.type === "phase_started") {
    const phase = (event.payload?.phase as string) || "";
    const iter = event.iteration;
    return (
      <div className="flex items-center gap-2 pt-2 pb-0.5">
        <div className="flex-1 h-px bg-slate-800" />
        <span className="uppercase tracking-wide text-[10px] text-indigo-300 font-semibold">
          {phaseLabel(phase)}
          {iter !== undefined && ` · iter ${iter}`}
        </span>
        <div className="flex-1 h-px bg-slate-800" />
      </div>
    );
  }

  const meta = describeEvent(event);
  const style = CATEGORY_STYLES[meta.category];
  const hasPayload = event.payload && Object.keys(event.payload).length > 0;

  return (
    <div
      onClick={() => hasPayload && setExpanded((v) => !v)}
      className={`rounded border border-slate-800 border-l-2 ${style.border} bg-slate-900/40 pl-2 pr-2 py-1.5 ${
        hasPayload ? "cursor-pointer hover:bg-slate-900/70" : ""
      }`}
    >
      <div className="flex items-baseline gap-2">
        <span className={`font-mono w-3 text-center ${style.text}`}>{meta.icon}</span>
        <span className={`${style.text} font-medium`}>{meta.label}</span>
        {event.agent && <span className="text-slate-500">· {event.agent}</span>}
        {event.iteration !== undefined && (
          <span className="text-slate-500">· iter {event.iteration}</span>
        )}
        <span className="flex-1" />
        <span
          className="text-[10px] text-slate-500 shrink-0"
          title={new Date(event.ts * 1000).toLocaleString()}
        >
          {relativeTime(event.ts, now)}
        </span>
      </div>
      {meta.inline.length > 0 && (
        <div className="mt-0.5 flex flex-wrap gap-x-3 gap-y-0.5 text-[11px] text-slate-400">
          {meta.inline.map((f, i) => (
            <span key={i}>
              <span className="text-slate-500">{f.key}:</span>{" "}
              <span className="font-mono break-all">{f.value}</span>
            </span>
          ))}
        </div>
      )}
      {expanded && hasPayload && (
        <pre className="text-[10px] text-slate-400 mt-1 whitespace-pre-wrap break-all font-mono">
          {JSON.stringify(event.payload, null, 2)}
        </pre>
      )}
    </div>
  );
}
