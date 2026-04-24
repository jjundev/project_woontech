import type { AgentUsagePayload, HarnessEvent } from "./types";

export interface AgentCostRow {
  agent: string;
  calls: number;
  input_tokens: number;
  output_tokens: number;
  cache_read_input_tokens: number;
  cache_creation_input_tokens: number;
  total_cost_usd: number;
  duration_ms: number;
}

export interface PhaseCostRow {
  phase: string;
  calls: number;
  total_cost_usd: number;
}

export interface CostSummary {
  total_cost_usd: number;
  total_input_tokens: number;
  total_output_tokens: number;
  total_cache_read_input_tokens: number;
  total_cache_creation_input_tokens: number;
  total_calls: number;
  by_agent: AgentCostRow[];
  by_phase: PhaseCostRow[];
}

const PHASE_BY_AGENT: Record<string, string> = {
  planner: "planning",
  plan_reviewer: "plan_review",
  implementor: "implementing",
  implement_reviewer: "impl_review",
  publisher: "publishing",
};

function getUsage(event: HarnessEvent): AgentUsagePayload | null {
  if (event.type !== "agent_usage") return null;
  const p = event.payload as Partial<AgentUsagePayload> | undefined;
  if (!p) return null;
  return {
    model: (p.model as string | null | undefined) ?? null,
    input_tokens: Number(p.input_tokens ?? 0),
    output_tokens: Number(p.output_tokens ?? 0),
    cache_creation_input_tokens: Number(p.cache_creation_input_tokens ?? 0),
    cache_read_input_tokens: Number(p.cache_read_input_tokens ?? 0),
    total_cost_usd:
      p.total_cost_usd === null || p.total_cost_usd === undefined
        ? null
        : Number(p.total_cost_usd),
    duration_ms:
      p.duration_ms === null || p.duration_ms === undefined
        ? null
        : Number(p.duration_ms),
    model_usage: (p.model_usage as Record<string, unknown> | null | undefined) ?? null,
  };
}

export function summarizeCost(events: HarnessEvent[]): CostSummary {
  const byAgent = new Map<string, AgentCostRow>();
  const byPhase = new Map<string, PhaseCostRow>();
  const summary: CostSummary = {
    total_cost_usd: 0,
    total_input_tokens: 0,
    total_output_tokens: 0,
    total_cache_read_input_tokens: 0,
    total_cache_creation_input_tokens: 0,
    total_calls: 0,
    by_agent: [],
    by_phase: [],
  };

  for (const event of events) {
    const usage = getUsage(event);
    if (!usage) continue;
    const agent = event.agent ?? "(unknown)";
    const phase = PHASE_BY_AGENT[agent] ?? "other";
    const cost = usage.total_cost_usd ?? 0;

    summary.total_cost_usd += cost;
    summary.total_input_tokens += usage.input_tokens;
    summary.total_output_tokens += usage.output_tokens;
    summary.total_cache_read_input_tokens += usage.cache_read_input_tokens;
    summary.total_cache_creation_input_tokens += usage.cache_creation_input_tokens;
    summary.total_calls += 1;

    const a = byAgent.get(agent) ?? {
      agent,
      calls: 0,
      input_tokens: 0,
      output_tokens: 0,
      cache_read_input_tokens: 0,
      cache_creation_input_tokens: 0,
      total_cost_usd: 0,
      duration_ms: 0,
    };
    a.calls += 1;
    a.input_tokens += usage.input_tokens;
    a.output_tokens += usage.output_tokens;
    a.cache_read_input_tokens += usage.cache_read_input_tokens;
    a.cache_creation_input_tokens += usage.cache_creation_input_tokens;
    a.total_cost_usd += cost;
    a.duration_ms += usage.duration_ms ?? 0;
    byAgent.set(agent, a);

    const ph = byPhase.get(phase) ?? { phase, calls: 0, total_cost_usd: 0 };
    ph.calls += 1;
    ph.total_cost_usd += cost;
    byPhase.set(phase, ph);
  }

  summary.by_agent = [...byAgent.values()].sort((a, b) => b.total_cost_usd - a.total_cost_usd);
  summary.by_phase = [...byPhase.values()].sort((a, b) => b.total_cost_usd - a.total_cost_usd);
  return summary;
}

export function formatUSD(value: number): string {
  if (!Number.isFinite(value)) return "$0.00";
  if (value === 0) return "$0.00";
  if (value < 0.01) return `$${value.toFixed(4)}`;
  if (value < 1) return `$${value.toFixed(3)}`;
  return `$${value.toFixed(2)}`;
}

export function formatTokens(value: number): string {
  if (!Number.isFinite(value) || value === 0) return "0";
  if (value < 1000) return value.toString();
  if (value < 1_000_000) return `${(value / 1000).toFixed(1)}k`;
  return `${(value / 1_000_000).toFixed(2)}M`;
}

export function formatDuration(ms: number): string {
  if (!Number.isFinite(ms) || ms <= 0) return "0s";
  if (ms < 1000) return `${ms}ms`;
  const s = Math.round(ms / 1000);
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  const rs = s % 60;
  if (m < 60) return `${m}m ${rs}s`;
  const h = Math.floor(m / 60);
  return `${h}h ${m % 60}m`;
}
