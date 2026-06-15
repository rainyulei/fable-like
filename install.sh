#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${FABLE_LITE_HOME:-$HOME/.claude/opus-to-fable}"
SETTINGS_FILE="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
LOCAL_BIN="${FABLE_LITE_BIN_DIR:-$HOME/.local/bin}"

mkdir -p "$INSTALL_DIR/hooks" "$INSTALL_DIR/prompts" "$INSTALL_DIR/output-styles" "$INSTALL_DIR/skills/fable-lite" "$(dirname "$SETTINGS_FILE")" "$LOCAL_BIN" "$HOME/.claude/output-styles" "$HOME/.claude/skills"
cp "$ROOT/hooks/fable-lite-context.sh" "$INSTALL_DIR/hooks/fable-lite-context.sh"
cp "$ROOT/prompts/fable-lite.md" "$INSTALL_DIR/prompts/fable-lite.md"
cp "$ROOT/output-styles/fable-lite.md" "$INSTALL_DIR/output-styles/fable-lite.md"
cp "$ROOT/skills/fable-lite/SKILL.md" "$INSTALL_DIR/skills/fable-lite/SKILL.md"
cp "$ROOT/bin/fable-lite" "$INSTALL_DIR/fable-lite"
chmod +x "$INSTALL_DIR/hooks/fable-lite-context.sh" "$INSTALL_DIR/fable-lite"

ln -sf "$INSTALL_DIR/fable-lite" "$LOCAL_BIN/fable-lite"

safe_link() {
  local source="$1"
  local dest="$2"
  if [ -L "$dest" ]; then
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    printf 'Refusing to overwrite existing non-symlink path: %s\n' "$dest" >&2
    printf 'Move or remove that path, then rerun install.sh.\n' >&2
    exit 1
  fi
  ln -s "$source" "$dest"
}

safe_link "$INSTALL_DIR/output-styles/fable-lite.md" "$HOME/.claude/output-styles/fable-lite.md"
safe_link "$INSTALL_DIR/skills/fable-lite" "$HOME/.claude/skills/fable-lite"

python3 - "$SETTINGS_FILE" "$INSTALL_DIR/hooks/fable-lite-context.sh" <<'PY'
import json
import os
import sys

settings_path, hook_path = sys.argv[1], sys.argv[2]
if os.path.exists(settings_path):
    with open(settings_path, "r", encoding="utf-8") as f:
        content = f.read().strip()
    settings = json.loads(content) if content else {}
else:
    settings = {}

hooks = settings.setdefault("hooks", {})

def ensure_event(event, matcher=None):
    groups = hooks.setdefault(event, [])
    group = None
    for candidate in groups:
        if matcher is None:
            if "matcher" not in candidate:
                group = candidate
                break
        elif candidate.get("matcher") == matcher:
            group = candidate
            break
    if group is None:
        group = {"hooks": []}
        if matcher is not None:
            group["matcher"] = matcher
        groups.append(group)
    entries = group.setdefault("hooks", [])
    command = hook_path
    for entry in entries:
        if entry.get("type") == "command" and entry.get("command") == command:
            entry["timeout"] = 5
            return
    entries.append({
        "type": "command",
        "command": command,
        "timeout": 5,
        "statusMessage": "Applying Fable Lite context"
    })

ensure_event("SessionStart", "startup|resume|clear|compact")
ensure_event("UserPromptSubmit")

for group in hooks.get("Stop", []):
    group["hooks"] = [
        entry for entry in group.get("hooks", [])
        if not (entry.get("type") == "command" and entry.get("command") == hook_path)
    ]
hooks["Stop"] = [group for group in hooks.get("Stop", []) if group.get("hooks")]
if not hooks.get("Stop"):
    hooks.pop("Stop", None)

with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PY

cat <<EOF
Installed Fable Lite v0.2.

Command:
  $LOCAL_BIN/fable-lite status

Optional Claude Code output style:
  /output-style fable-lite

If $LOCAL_BIN is not on PATH, either add it or run:
  $INSTALL_DIR/fable-lite on
EOF
