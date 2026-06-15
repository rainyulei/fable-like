#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export FABLE_LITE_HOME="$TMP/home/.claude/opus-to-fable"
mkdir -p "$FABLE_LITE_HOME/hooks" "$FABLE_LITE_HOME/prompts" "$TMP/project"
cp "$ROOT/hooks/fable-lite-context.sh" "$FABLE_LITE_HOME/hooks/fable-lite-context.sh"
cp "$ROOT/prompts/fable-lite.md" "$FABLE_LITE_HOME/prompts/fable-lite.md"
cp "$ROOT/prompts/stop-reminder.md" "$FABLE_LITE_HOME/prompts/stop-reminder.md"

hook_input='{"cwd":"'"$TMP/project"'","model":"claude-opus-4-8","hook_event_name":"SessionStart"}'

disabled_output="$(printf '%s' "$hook_input" | "$ROOT/hooks/fable-lite-context.sh")"
if [ -n "$disabled_output" ]; then
  printf 'Expected disabled hook to emit nothing, got: %s\n' "$disabled_output" >&2
  exit 1
fi

"$ROOT/bin/fable-lite" on >/dev/null
enabled_output="$(printf '%s' "$hook_input" | "$ROOT/hooks/fable-lite-context.sh")"
printf '%s' "$enabled_output" | python3 -c 'import json,sys; data=json.load(sys.stdin); assert "Fable Lite Behavior Layer" in data["hookSpecificOutput"]["additionalContext"]'
printf '%s' "$enabled_output" | python3 -c 'import json,sys; data=json.load(sys.stdin); text=data["hookSpecificOutput"]["additionalContext"]; assert "## 1. Communication" in text and "## 8. Token Economy" in text'

prompt_submit_input='{"cwd":"'"$TMP/project"'","model":"claude-opus-4-8","hook_event_name":"UserPromptSubmit"}'
prompt_submit_output="$(printf '%s' "$prompt_submit_input" | "$ROOT/hooks/fable-lite-context.sh")"
printf '%s' "$prompt_submit_output" | python3 -c 'import json,sys; data=json.load(sys.stdin); assert data["hookSpecificOutput"]["hookEventName"] == "UserPromptSubmit"'

stop_input='{"cwd":"'"$TMP/project"'","model":"claude-opus-4-8","hook_event_name":"Stop"}'
stop_output="$(printf '%s' "$stop_input" | "$ROOT/hooks/fable-lite-context.sh")"
printf '%s' "$stop_output" | python3 -c 'import json,sys; data=json.load(sys.stdin); assert data["hookSpecificOutput"]["hookEventName"] == "Stop"; assert "Before ending the turn" in data["hookSpecificOutput"]["additionalContext"]'

cd "$TMP/project"
"$ROOT/bin/fable-lite" project off >/dev/null
project_disabled_output="$(printf '%s' "$hook_input" | "$ROOT/hooks/fable-lite-context.sh")"
if [ -n "$project_disabled_output" ]; then
  printf 'Expected project override off to emit nothing, got: %s\n' "$project_disabled_output" >&2
  exit 1
fi

status_output="$("$ROOT/bin/fable-lite" status)"
printf '%s\n' "$status_output" | grep -q 'global: on'
printf '%s\n' "$status_output" | grep -q 'project: off'

install_tmp="$TMP/install"
env -u FABLE_LITE_HOME HOME="$install_tmp/home" FABLE_LITE_BIN_DIR="$install_tmp/bin" "$ROOT/install.sh" >/dev/null
test -f "$install_tmp/home/.claude/opus-to-fable/output-styles/fable-lite.md"
test -f "$install_tmp/home/.claude/opus-to-fable/skills/fable-lite/SKILL.md"
test -L "$install_tmp/home/.claude/output-styles/fable-lite.md" || {
  ls -la "$install_tmp/home/.claude/output-styles" >&2
  exit 1
}
test -L "$install_tmp/home/.claude/skills/fable-lite" || {
  ls -la "$install_tmp/home/.claude/skills" >&2
  exit 1
}
python3 - "$install_tmp/home/.claude/settings.json" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    settings = json.load(f)
hooks = settings["hooks"]
assert "SessionStart" in hooks
assert "UserPromptSubmit" in hooks
assert "Stop" in hooks
PY

conflict_tmp="$TMP/conflict"
mkdir -p "$conflict_tmp/home/.claude/skills/fable-lite"
printf 'user skill\n' > "$conflict_tmp/home/.claude/skills/fable-lite/KEEP.md"
if env -u FABLE_LITE_HOME HOME="$conflict_tmp/home" FABLE_LITE_BIN_DIR="$conflict_tmp/bin" "$ROOT/install.sh" >/dev/null 2>"$conflict_tmp/install.err"; then
  printf 'Expected installer to fail instead of overwriting existing skill directory.\n' >&2
  exit 1
fi
test -f "$conflict_tmp/home/.claude/skills/fable-lite/KEEP.md"
grep -q 'Refusing to overwrite' "$conflict_tmp/install.err"

test -f "$ROOT/.claude-plugin/plugin.json"
test -f "$ROOT/hooks/hooks.json"
python3 - "$ROOT/.claude-plugin/plugin.json" "$ROOT/hooks/hooks.json" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    manifest = json.load(f)
assert manifest["name"] == "opus-to-fable"
assert manifest["displayName"] == "Opus to Fable Lite"
assert manifest["defaultEnabled"] is False
with open(sys.argv[2], "r", encoding="utf-8") as f:
    hooks = json.load(f)["hooks"]
assert "SessionStart" in hooks
assert "UserPromptSubmit" in hooks
assert "Stop" in hooks
PY

mkdir -p "$TMP/plugin-project"
plugin_input='{"cwd":"'"$TMP/plugin-project"'","model":"claude-opus-4-8","hook_event_name":"SessionStart"}'
plugin_output="$(printf '%s' "$plugin_input" | env -u FABLE_LITE_HOME CLAUDE_PLUGIN_ROOT="$ROOT" HOME="$TMP/plugin-home" "$ROOT/hooks/fable-lite-context.sh")"
printf '%s' "$plugin_output" | python3 -c 'import json,sys; data=json.load(sys.stdin); assert "## 1. Communication" in data["hookSpecificOutput"]["additionalContext"]'

printf 'All smoke tests passed.\n'
