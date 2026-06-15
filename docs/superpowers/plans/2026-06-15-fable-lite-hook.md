# Fable Lite Hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code extension package that lets users toggle an Opus 4.8 "Fable 5 lite" behavior layer globally, with per-project overrides.

**Architecture:** A CLI writes simple state files under `~/.claude/opus-to-fable`. Claude Code runs `SessionStart` and `UserPromptSubmit` hooks that read global state plus project override files, then inject an 8-section operating contract via `hookSpecificOutput.additionalContext` only when enabled. The installer also registers an optional output style and skill for persistent Fable Lite behavior.

**Tech Stack:** POSIX shell, Python 3 for JSON-safe settings merge and hook output, Claude Code `settings.json` hooks.

---

### Task 1: Hook Runtime

**Files:**
- Create: `hooks/fable-lite-context.sh`
- Create: `prompts/fable-lite.md`

- [x] **Step 1: Add a maintainable prompt file**

Create `prompts/fable-lite.md` with result-first coding behavior, autonomy boundaries, verification expectations, and safety limits.

- [x] **Step 2: Add hook script**

Create `hooks/fable-lite-context.sh` to read Claude Code hook JSON from stdin, decide whether the mode is enabled, and emit `additionalContext`.

- [x] **Step 3: Make hook executable**

Run: `chmod +x hooks/fable-lite-context.sh`

### Task 2: User Toggle CLI

**Files:**
- Create: `bin/fable-lite`

- [x] **Step 1: Implement `on`, `off`, and `status`**

Use state files under `${FABLE_LITE_HOME:-$HOME/.claude/opus-to-fable}`.

- [x] **Step 2: Implement project override commands**

Support `project on`, `project off`, and `project clear` by writing `.claude/opus-to-fable.json` in the current project.

### Task 3: Installer

**Files:**
- Create: `install.sh`
- Create: `uninstall.sh`

- [x] **Step 1: Copy package files**

Install scripts and prompt into `~/.claude/opus-to-fable`.

- [x] **Step 2: Merge hooks into `~/.claude/settings.json`**

Use Python JSON parsing to idempotently add `SessionStart` and `UserPromptSubmit` command hooks.

- [x] **Step 3: Uninstall safely**

Remove only hook entries whose command points to the installed fable-lite hook.

### Task 4: Tests And Docs

**Files:**
- Create: `tests/run.sh`
- Create: `README.md`

- [x] **Step 1: Add smoke tests**

Test disabled state, global enabled state, project disabled override, and CLI status output using a temporary HOME.

- [x] **Step 2: Add usage docs**

Document install, toggles, project overrides, behavior limits, and uninstall.

### Task 5: V0.2 Multi-Layer Upgrade

**Files:**
- Modify: `prompts/fable-lite.md`
- Create: `prompts/stop-reminder.md`
- Create: `output-styles/fable-lite.md`
- Create: `skills/fable-lite/SKILL.md`
- Modify: `hooks/fable-lite-context.sh`
- Modify: `install.sh`
- Modify: `uninstall.sh`
- Modify: `tests/run.sh`
- Modify: `README.md`

- [x] **Step 1: Expand prompt into 8-section operating contract**

Cover communication, effort/reasoning, tool discipline, autonomy/scope, code quality, verification, safety, and token economy without copying leaked system prompt text.

- [x] **Step 2: Add Stop reminder behavior**

Use a separate prompt for `Stop` hook events so Claude gets an evidence-before-completion reminder instead of the full contract.

- [x] **Step 3: Add output style and skill layers**

Install optional Claude Code output style and skill symlinks alongside deterministic hooks.

- [x] **Step 4: Make installer non-destructive**

Refuse to overwrite existing non-symlink output style or skill paths.

- [x] **Step 5: Verify**

Run: `./tests/run.sh`
Expected: `All smoke tests passed.`

Run: `bash -n bin/fable-lite hooks/fable-lite-context.sh install.sh uninstall.sh tests/run.sh`
Expected: exit 0 with no output.

### Task 6: Formal Claude Code Plugin Packaging

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `hooks/hooks.json`
- Modify: `hooks/fable-lite-context.sh`
- Modify: `tests/run.sh`
- Modify: `README.md`

- [x] **Step 1: Add plugin manifest**

Create `.claude-plugin/plugin.json` with name `opus-to-fable`, display name, description, version, author, and `defaultEnabled: false`.

- [x] **Step 2: Add local marketplace**

Create `.claude-plugin/marketplace.json` so Claude Code can add this repo as a local marketplace and install `opus-to-fable@opus-to-fable-local`.

- [x] **Step 3: Add plugin hook config**

Create `hooks/hooks.json` with `SessionStart`, `UserPromptSubmit`, and `Stop` entries that call `${CLAUDE_PLUGIN_ROOT}/hooks/fable-lite-context.sh`.

- [x] **Step 4: Make hook plugin-aware**

When `CLAUDE_PLUGIN_ROOT` is present, read prompt files from the plugin root and treat plugin enablement as the primary toggle.

- [x] **Step 5: Verify**

Run: `./tests/run.sh`
Expected: `All smoke tests passed.`

Run: `claude plugin validate .`
Expected: `Validation passed`.

Run: `bash -n bin/fable-lite hooks/fable-lite-context.sh install.sh uninstall.sh tests/run.sh`
Expected: exit 0 with no output.

### Task 7: Remove Stop Hook Loop

**Files:**
- Modify: `hooks/hooks.json`
- Modify: `hooks/fable-lite-context.sh`
- Modify: `install.sh`
- Modify: `tests/run.sh`
- Modify: `README.md`
- Delete: `prompts/stop-reminder.md`

- [x] **Step 1: Remove Stop hook registration**

Remove `Stop` from plugin hooks and from CLI installer registration. Keep installer cleanup so an old CLI install removes the previously registered Stop hook command.

- [x] **Step 2: Make Stop input silent**

If the hook receives `hook_event_name: "Stop"`, exit 0 with no output. This prevents Claude Code from treating hook feedback as a reason to block turn completion.

- [x] **Step 3: Verify**

Run: `./tests/run.sh`
Expected: `All smoke tests passed.`

Run: `claude plugin validate .`
Expected: `Validation passed`.
