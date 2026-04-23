import type { TaskState } from "./types";

async function j<T>(res: Response): Promise<T> {
  if (!res.ok) throw new Error(`${res.status} ${await res.text()}`);
  return res.json() as Promise<T>;
}

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
  createTask: (title: string) =>
    fetch("/api/tasks", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ title }),
    }).then((r) => j<TaskState>(r)),
  spectorMessage: (id: string, text: string) =>
    fetch(`/api/tasks/${id}/spector/message`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ text }),
    }).then((r) => j<{ reply: string; confirmed: boolean }>(r)),
  spectorClose: (id: string) =>
    fetch(`/api/tasks/${id}/spector/close`, { method: "POST" }).then((r) => j<{ ok: true }>(r)),
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
