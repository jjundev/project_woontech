export type TaskStateName =
  | "draft"
  | "todo"
  | "planning"
  | "plan_review"
  | "implementing"
  | "impl_review"
  | "publishing"
  | "done"
  | "needs_attention"
  | "paused";

export interface TaskState {
  id: string;
  state: TaskStateName;
  paused_from: TaskStateName | null;
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
  run_id?: string | null;
  agent?: string;
  iteration?: number;
  payload: Record<string, unknown>;
  ts: number;
}

export interface AgentUsagePayload {
  model?: string | null;
  input_tokens: number;
  output_tokens: number;
  cache_creation_input_tokens: number;
  cache_read_input_tokens: number;
  total_cost_usd?: number | null;
  duration_ms?: number | null;
  model_usage?: Record<string, unknown> | null;
}

export interface PlanStep {
  index: number;
  title: string;
}

export interface PlanStepsPayload {
  steps: PlanStep[];
}

export interface PlanStepProgressPayload {
  marker: string;
}
