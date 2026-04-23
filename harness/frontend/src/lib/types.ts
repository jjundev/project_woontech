export type TaskStateName =
  | "draft"
  | "todo"
  | "planning"
  | "plan_review"
  | "implementing"
  | "impl_review"
  | "publishing"
  | "done"
  | "needs_attention";

export interface TaskState {
  id: string;
  state: TaskStateName;
  title: string;
  plan_version: number;
  impl_version: number;
  plan_retries: number;
  impl_retries: number;
  max_plan_retries: number;
  max_impl_retries: number;
  escalation: string | null;
  created_at: number;
  updated_at: number;
  branch: string | null;
  pr_url: string | null;
}

export interface HarnessEvent {
  type: string;
  task_id?: string;
  agent?: string;
  iteration?: number;
  payload: Record<string, unknown>;
  ts: number;
}
