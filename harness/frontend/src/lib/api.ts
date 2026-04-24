import type { PlanStepsPayload, TaskState } from "./types";

async function j<T>(res: Response): Promise<T> {
  if (!res.ok) throw new Error(`${res.status} ${await res.text()}`);
  return res.json() as Promise<T>;
}

export type WorktreeFile = { path: string; change: string };
export type WorktreeStatus = {
  exists: boolean;
  branch: string | null;
  files: WorktreeFile[];
  commits_ahead: number;
};

export type WorktreeBase = "local" | "remote";

type StartOpts = {
  max_plan_retries?: number;
  max_impl_retries?: number;
  worktree_base?: WorktreeBase;
  resume_from?: "impl_review";
};

function encodePath(path: string): string {
  return path.split("/").map(encodeURIComponent).join("/");
}

export const api = {
  listTasks: () => fetch("/api/tasks").then((r) => j<TaskState[]>(r)),
  getTask: (id: string) =>
    fetch(`/api/tasks/${id}`).then((r) =>
      j<{ state: TaskState; files: string[]; task_dir: string }>(r),
    ),
  getPlanSteps: (id: string) =>
    fetch(`/api/tasks/${id}/plan-steps`).then((r) => j<PlanStepsPayload>(r)),
  getFile: (id: string, name: string) =>
    fetch(`/api/tasks/${id}/files/${encodeURIComponent(name)}`).then((r) =>
      j<{ name: string; content: string }>(r),
    ),
  getWorktreeFile: (id: string, path: string) =>
    fetch(`/api/tasks/${id}/worktree-files/${encodePath(path)}`).then((r) =>
      j<{ path: string; content: string }>(r),
    ),
  getWorktreeStatus: (id: string) =>
    fetch(`/api/tasks/${id}/worktree-status`).then((r) => j<WorktreeStatus>(r)),
  startPipeline: (id: string, opts: StartOpts) =>
    fetch(`/api/tasks/${id}/start`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(opts),
    }).then((r) => j<{ ok: true }>(r)),
  resumePipeline: (id: string, opts: StartOpts) =>
    fetch(`/api/tasks/${id}/resume`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(opts),
    }).then((r) => j<{ ok: true }>(r)),
  pausePipeline: (id: string) =>
    fetch(`/api/tasks/${id}/pause`, { method: "POST" }).then((r) => j<{ ok: true }>(r)),
};
