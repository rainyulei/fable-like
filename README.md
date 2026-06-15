# Opus to Fable Lite

Claude Code extension package for making Opus 4.8 feel more like a "Fable 5 lite" coding assistant: terse, action-first, tool-heavy, and verification-oriented.

This does not change model weights or unlock Claude Fable 5. It layers operating discipline on top of available Claude Code models.

## What It Installs

The package has four layers:

- `prompts/fable-lite.md`: 8-section operating contract covering communication, effort, tool discipline, autonomy, code quality, verification, safety, and token economy.
- `hooks/fable-lite-context.sh`: `SessionStart` and `UserPromptSubmit` hook entrypoint.
- `output-styles/fable-lite.md`: optional Claude Code output style for persistent response style.
- `skills/fable-lite/SKILL.md`: skill trigger for Fable-like behavior requests.

## Recommended: Claude Code Plugin Install

This repo is now a formal Claude Code plugin marketplace. From Claude Code, add the local marketplace and install the plugin:

```text
/plugin marketplace add /Users/rainlei/holiday/opus_to_fable
/plugin install opus-to-fable@opus-to-fable-local
```

The plugin ships:

- `hooks/hooks.json`
- `skills/fable-lite/SKILL.md`
- `output-styles/fable-lite.md`
- prompts used by the hook runtime

The plugin manifest sets `"defaultEnabled": false`, so enable it when you want the mode:

```text
/plugin enable opus-to-fable
```

Disable it when you want normal Claude Code behavior:

```text
/plugin disable opus-to-fable
```

For local development without installing:

```bash
claude --plugin-dir .
```

## Alternative: CLI Install

```bash
./install.sh
```

The installer:

- copies package files into `~/.claude/opus-to-fable`
- adds hooks to `~/.claude/settings.json`
- links `fable-lite` into `~/.local/bin`
- links the output style into `~/.claude/output-styles/fable-lite.md`
- links the skill into `~/.claude/skills/fable-lite`

If `~/.local/bin` is not on your `PATH`, run the installed command directly:

```bash
~/.claude/opus-to-fable/fable-lite status
```

## CLI Global Toggle

```bash
fable-lite on
fable-lite off
fable-lite status
```

When global mode is off, the hook exits silently and injects nothing.

## Project Overrides

Run these from a project root:

```bash
fable-lite project on
fable-lite project off
fable-lite project clear
```

Project overrides write `.claude/opus-to-fable.json`.

Precedence:

1. project override, when present
2. plugin enabled state, when running as a Claude Code plugin
3. global state in `~/.claude/opus-to-fable/enabled`, when using CLI install

## Optional Output Style

After installing the plugin or CLI version, start a new Claude Code session and run:

```text
/output-style fable-lite
```

The hook toggle and output style are separate:

- hook toggle controls deterministic per-session/per-turn context injection
- output style controls Claude Code response style through its style system

## Uninstall

```bash
./uninstall.sh
```

The uninstaller removes only hook entries pointing at this package's installed hook path, then removes installed package files and symlinks.

## Test

```bash
./tests/run.sh
```
