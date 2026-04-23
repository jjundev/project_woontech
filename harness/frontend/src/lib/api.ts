import type { TaskState } from "./types";

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

export const api = {
  listTasks: () => fetch("/api/tasks").then((r) => j<TaskState[]>(r)),
  getTask: (id: string) =>
    fetch(`/api/tasks/${id}`).then((r) =>
      j<{ state: TaskState; files: string[]; task_dir: string }>(r),
    ),
  getFile: (id: string, name: string) =>
    fetch(`/api/tasks/${id}/files/${encodeURIComponent(name)}`).then((r) =>
      j<{ name: string; content: string }>(r),
    ),
  getWorktreeStatus: (id: string) =>
    fetch(`/api/tasks/${id}/worktree-status`).then((r) => j<WorktreeStatus>(r)),
  startPipeline: (id: string, opts: { max_plan_retries?: number; max_impl_retries?: number }) =>
    fetch(`/api/tasks/${id}/start`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(opts),
    }).then((r) => j<{ ok: true }>(r)),
  resumePipeline: (id: string, opts: { max_plan_retries?: number; max_impl_retries?: number }) =>
    fetch(`/api/tasks/${id}/resume`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(opts),
    }).then((r) => j<{ ok: true }>(r)),
};
