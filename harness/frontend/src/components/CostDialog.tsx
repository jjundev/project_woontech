import { useEffect, useMemo } from "react";
import {
  formatDuration,
  formatTokens,
  formatUSD,
  summarizeCost,
} from "../lib/cost";
import { agentStyle } from "../lib/timeline";
import type { HarnessEvent } from "../lib/types";

export function CostDialog({
  events,
  onClose,
}: {
  events: HarnessEvent[];
  onClose: () => void;
}) {
  const summary = useMemo(() => summarizeCost(events), [events]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-50 bg-black/60 flex items-start justify-center pt-16 px-4"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="bg-slate-900 border border-slate-700 rounded-lg shadow-xl w-full max-w-3xl max-h-[80vh] overflow-auto"
      >
        <div className="px-4 py-3 border-b border-slate-800 flex items-center gap-3">
          <h2 className="text-base font-semibold text-slate-100">Token usage & cost</h2>
          <span className="text-xs text-slate-500">· {summary.total_calls} agent calls</span>
          <div className="flex-1" />
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-100 text-sm"
            aria-label="Close"
          >
            ✕
          </button>
        </div>

        <div className="p-4 space-y-5 text-sm">
          <SummaryGrid summary={summary} />
          <ByAgentTable summary={summary} />
          <ByPhaseTable summary={summary} />
          <p className="text-[11px] text-slate-500">
            Cost values come from the Claude Agent SDK&apos;s reported{" "}
            <code className="font-mono">total_cost_usd</code> on each agent run.
            Use as an estimate.
          </p>
        </div>
      </div>
    </div>
  );
}

function SummaryGrid({ summary }: { summary: ReturnType<typeof summarizeCost> }) {
  const items: { label: string; value: string }[] = [
    { label: "Total cost", value: formatUSD(summary.total_cost_usd) },
    { label: "Input", value: formatTokens(summary.total_input_tokens) },
    { label: "Output", value: formatTokens(summary.total_output_tokens) },
    { label: "Cache read", value: formatTokens(summary.total_cache_read_input_tokens) },
    { label: "Cache write", value: formatTokens(summary.total_cache_creation_input_tokens) },
  ];
  return (
    <div className="grid grid-cols-5 gap-2">
      {items.map((item) => (
        <div
          key={item.label}
          className="bg-slate-950/50 border border-slate-800 rounded px-3 py-2"
        >
          <div className="text-[10px] uppercase text-slate-500">{item.label}</div>
          <div className="text-base font-mono text-slate-100">{item.value}</div>
        </div>
      ))}
    </div>
  );
}

function ByAgentTable({ summary }: { summary: ReturnType<typeof summarizeCost> }) {
  if (summary.by_agent.length === 0) {
    return (
      <div className="text-slate-500 text-xs">No agent_usage events recorded yet.</div>
    );
  }
  return (
    <div>
      <div className="text-xs uppercase text-slate-500 mb-1">By agent</div>
      <table className="w-full text-xs">
        <thead>
          <tr className="text-slate-500 border-b border-slate-800">
            <th className="text-left font-normal py-1">Agent</th>
            <th className="text-right font-normal">Calls</th>
            <th className="text-right font-normal">Input</th>
            <th className="text-right font-normal">Output</th>
            <th className="text-right font-normal">Cache R</th>
            <th className="text-right font-normal">Cache W</th>
            <th className="text-right font-normal">Cost</th>
            <th className="text-right font-normal">Time</th>
          </tr>
        </thead>
        <tbody>
          {summary.by_agent.map((row) => {
            const style = agentStyle(row.agent);
            return (
              <tr key={row.agent} className="border-b border-slate-800/40">
                <td className={`py-1 ${style.text}`}>{style.label}</td>
                <td className="text-right font-mono text-slate-300">{row.calls}</td>
                <td className="text-right font-mono text-slate-300">
                  {formatTokens(row.input_tokens)}
                </td>
                <td className="text-right font-mono text-slate-300">
                  {formatTokens(row.output_tokens)}
                </td>
                <td className="text-right font-mono text-slate-400">
                  {formatTokens(row.cache_read_input_tokens)}
                </td>
                <td className="text-right font-mono text-slate-400">
                  {formatTokens(row.cache_creation_input_tokens)}
                </td>
                <td className="text-right font-mono text-emerald-300">
                  {formatUSD(row.total_cost_usd)}
                </td>
                <td className="text-right font-mono text-slate-400">
                  {formatDuration(row.duration_ms)}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

function ByPhaseTable({ summary }: { summary: ReturnType<typeof summarizeCost> }) {
  if (summary.by_phase.length === 0) return null;
  return (
    <div>
      <div className="text-xs uppercase text-slate-500 mb-1">By phase</div>
      <table className="w-full text-xs">
        <thead>
          <tr className="text-slate-500 border-b border-slate-800">
            <th className="text-left font-normal py-1">Phase</th>
            <th className="text-right font-normal">Calls</th>
            <th className="text-right font-normal">Cost</th>
          </tr>
        </thead>
        <tbody>
          {summary.by_phase.map((row) => (
            <tr key={row.phase} className="border-b border-slate-800/40">
              <td className="py-1 text-slate-300">{row.phase}</td>
              <td className="text-right font-mono text-slate-300">{row.calls}</td>
              <td className="text-right font-mono text-emerald-300">
                {formatUSD(row.total_cost_usd)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
