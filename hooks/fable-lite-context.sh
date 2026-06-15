#!/usr/bin/env bash
set -euo pipefail

STATE_HOME="${FABLE_LITE_HOME:-$HOME/.claude/opus-to-fable}"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

if [ -n "$PLUGIN_ROOT" ]; then
  PROMPT_FILE="$PLUGIN_ROOT/prompts/fable-lite.md"
else
  PROMPT_FILE="${STATE_HOME}/prompts/fable-lite.md"
fi
GLOBAL_STATE="${STATE_HOME}/enabled"

INPUT="$(cat)"

project_dir="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("cwd") or data.get("project_dir") or "")' 2>/dev/null || true)"
model="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("model") or "")' 2>/dev/null || true)"
hook_event_name="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("hook_event_name") or "SessionStart")' 2>/dev/null || true)"

if [ "$hook_event_name" = "Stop" ]; then
  exit 0
fi

enabled="false"
if [ -n "$PLUGIN_ROOT" ]; then
  enabled="true"
elif [ -f "$GLOBAL_STATE" ]; then
  enabled="true"
fi

if [ -n "$project_dir" ] && [ -f "$project_dir/.claude/opus-to-fable.json" ]; then
  override="$(python3 - "$project_dir/.claude/opus-to-fable.json" <<'PY' 2>/dev/null || true
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
value = data.get("enabled")
if value is True:
    print("true")
elif value is False:
    print("false")
PY
)"
  if [ "$override" = "true" ] || [ "$override" = "false" ]; then
    enabled="$override"
  fi
fi

if [ "$enabled" != "true" ]; then
  exit 0
fi

context_file="$PROMPT_FILE"

if [ ! -f "$context_file" ]; then
  exit 0
fi

python3 - "$context_file" "$model" "$hook_event_name" <<'PY'
import json
import sys

prompt_path = sys.argv[1]
model = sys.argv[2] if len(sys.argv) > 2 else ""
hook_event_name = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else "SessionStart"

with open(prompt_path, "r", encoding="utf-8") as f:
    prompt = f.read().strip()

model_note = ""
if model:
    model_note = f"\n\nActive model reported by Claude Code: `{model}`. Apply this as a behavior layer only; do not claim a different model identity."

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": hook_event_name,
        "additionalContext": f"{prompt}{model_note}"
    }
}, ensure_ascii=False))
PY
