#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_FILE="${1:-$ROOT/evals/tasks.json}"
MODEL="${FABLE_LITE_EVAL_MODEL:-opus}"
BUDGET="${FABLE_LITE_EVAL_BUDGET:-0.80}"
OUT_DIR="${FABLE_LITE_EVAL_OUT:-$ROOT/evals/results}"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude-work}"

mkdir -p "$OUT_DIR"

python3 - "$TASKS_FILE" <<'PY' | while IFS=$'\t' read -r id prompt; do
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    tasks = json.load(f)

for task in tasks:
    print(f"{task['id']}\t{task['prompt']}")
PY
  out_file="$OUT_DIR/$id.json"
  printf 'Running %s\n' "$id" >&2
  CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude -p \
    --model "$MODEL" \
    --max-budget-usd "$BUDGET" \
    --output-format json \
    "$prompt" > "$out_file" < /dev/null
done

printf 'Results written to %s\n' "$OUT_DIR"
