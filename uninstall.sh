#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${FABLE_LITE_HOME:-$HOME/.claude/opus-to-fable}"
SETTINGS_FILE="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
LOCAL_BIN="${FABLE_LITE_BIN_DIR:-$HOME/.local/bin}"
HOOK_PATH="$INSTALL_DIR/hooks/fable-lite-context.sh"

if [ -f "$SETTINGS_FILE" ]; then
  python3 - "$SETTINGS_FILE" "$HOOK_PATH" <<'PY'
import json
import os
import sys

settings_path, hook_path = sys.argv[1], sys.argv[2]
with open(settings_path, "r", encoding="utf-8") as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})
for event in ["SessionStart", "UserPromptSubmit", "Stop"]:
    groups = hooks.get(event, [])
    kept_groups = []
    for group in groups:
        entries = [
            entry for entry in group.get("hooks", [])
            if not (entry.get("type") == "command" and entry.get("command") == hook_path)
        ]
        if entries:
            group["hooks"] = entries
            kept_groups.append(group)
    if kept_groups:
        hooks[event] = kept_groups
    elif event in hooks:
        del hooks[event]

if not hooks and "hooks" in settings:
    del settings["hooks"]

with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PY
fi

rm -f "$LOCAL_BIN/fable-lite"
rm -f "$HOME/.claude/output-styles/fable-lite.md"
rm -f "$HOME/.claude/skills/fable-lite"
rm -rf "$INSTALL_DIR"

printf 'Uninstalled Fable Lite hook.\n'
