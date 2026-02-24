---
name: setup-agent-cli-hooks
description: Set up hooks and lifecycle configurations for multiple AI coding agent CLIs (Claude Code, Codex, OpenCode, Gemini CLI, and Amp). Use when configuring automation, lifecycle events, or shared hook scripts across different agent platforms.
disable-model-invocation: false
metadata:
  version: "1.0.0"
  author: ""
  tags: ["hooks", "cli", "setup", "claude-code", "codex", "opencode", "gemini-cli", "amp", "automation", "lifecycle"]
  license: ""
compatibility: "Requires bash 4.0+, optional jq for JSON manipulation"
---

# Setup Agent CLI Hooks

## When to Use

- Use when the user wants to set up lifecycle hooks for AI coding agents
- When automating tasks like linting, testing, or notifications after agent actions
- When configuring hooks across multiple agent CLIs (Claude Code, Codex, OpenCode, Gemini, Amp)
- When the user mentions "hooks", "automation", "lifecycle events", or "agent setup"

## Overview

Set up lifecycle hooks for all major AI coding agent CLIs in a project. This skill creates a unified hook system that works across **Claude Code**, **Codex CLI**, **OpenCode**, **Gemini CLI**, and **Amp** — using a single set of shared hook scripts with agent-specific configuration wrappers.

## Why This Matters

Each AI coding agent CLI has its own hook system with different formats:

| Agent CLI | Config Format | Hook Config Location | Hook Events |
|-----------|--------------|---------------------|-------------|
| Claude Code | JSON (settings.json) | `.claude/settings.json` | SessionStart, PreToolUse, PostToolUse, Stop, Notification, +more |
| Codex CLI | TOML (config.toml) | `.codex/config.toml` | notify (agent-turn-complete only) |
| OpenCode | TypeScript plugins | `.opencode/plugins/` | tool.execute.after, session.idle, +more |
| Gemini CLI | JSON (settings.json) | `.gemini/settings.json` | SessionStart, BeforeTool, AfterTool, AfterAgent, Notification, +more |
| Amp | Executable toolboxes | `.amp/toolboxes/` | describe/execute pattern |

This script creates a **shared hook layer** (`.agent-hooks/`) with portable bash scripts, then generates the agent-specific configuration wrappers for each CLI.

## Architecture

After running the setup script, the project will have:

```
your-project/
├── .agent-hooks/              # Shared hook scripts (portable bash)
│   ├── lint-on-edit.sh
│   ├── block-rm.sh
│   ├── test-on-write.sh
│   ├── notify-done.sh
│   └── session-context.sh
├── .claude/
│   └── settings.json          # Claude Code hooks config
├── .codex/
│   └── config.toml            # Codex CLI notify config
├── .opencode/
│   └── plugins/
│       └── agent-hooks.ts     # OpenCode TypeScript plugin
├── .gemini/
│   └── settings.json          # Gemini CLI hooks config
└── .amp/
    └── toolboxes/
        └── <tool-name>        # Amp toolbox executable
```

## Instructions

When the user invokes this skill, run the setup script to configure hooks for their project. The script auto-detects which agent CLIs are installed and creates the appropriate configuration for each.

### Running the Script

```bash
bash skills/setup-agent-cli-hooks/scripts/setup-agent-hooks.sh [OPTIONS]
```

### Available Options

| Option | Description | Default |
|--------|-------------|---------|
| `--project-dir DIR` | Target project directory | Current directory |
| `--scope SCOPE` | `project` (repo-level) or `user` (global) | `project` |
| `--hook-type TYPE` | Hook preset to install | `lint-on-edit` |
| `--custom-cmd CMD` | Command for `--hook-type custom` | — |
| `--dry-run` | Preview without writing files | `false` |
| `--list-agents` | Detect and list installed CLIs | — |
| `--list-hooks` | List available hook presets | — |

### Hook Presets

| Preset | Description | Agent Events |
|--------|-------------|-------------|
| `lint-on-edit` | Auto-lint files after edits | Claude: PostToolUse, Gemini: AfterTool |
| `block-rm` | Block destructive `rm` commands | Claude: PreToolUse, Gemini: BeforeTool |
| `test-on-write` | Run tests after file writes | Claude: PostToolUse, Gemini: AfterTool |
| `notify-done` | Notification when agent finishes | Claude: Stop, Gemini: AfterAgent, Codex: notify |
| `session-context` | Inject git context on start | Claude: SessionStart, Gemini: SessionStart |
| `custom` | User-provided command | Varies |

### How It Works

1. **Detection** — The script checks for installed agent CLIs (`claude`, `codex`, `opencode`, `gemini`, `amp`)
2. **Shared scripts** — Creates hook scripts in `.agent-hooks/` that work across all agents
3. **Agent configs** — Generates agent-specific configuration files:
   - Claude Code: `.claude/settings.json` with hooks object
   - Codex CLI: `.codex/config.toml` with `notify` key
   - OpenCode: `.opencode/plugins/agent-hooks.ts` TypeScript plugin
   - Gemini CLI: `.gemini/settings.json` with hooks object
   - Amp: `.amp/toolboxes/` with executable toolbox scripts
4. **Merge** — If existing settings files are found, hooks are merged (not overwritten)

### Agent-Specific Notes

- **Codex CLI** has limited hook support — only the `notify` key for `agent-turn-complete` events. Full lifecycle hooks are not yet available.
- **OpenCode** uses TypeScript plugins rather than JSON configuration. The script generates a `.ts` plugin that wraps the shared hook scripts.
- **Amp** uses "toolboxes" (self-describing executable scripts) instead of hooks. Set the `AMP_TOOLBOX` environment variable to the toolboxes directory to enable them.

## Hook Preset Details

### `lint-on-edit` (default)

Runs a linter on files after they are edited or written. Auto-detects the language and linter:

- **JS/TS**: ESLint
- **Python**: ruff / flake8
- **Go**: golangci-lint
- **Rust**: cargo clippy
- **Ruby**: RuboCop

### `block-rm`

Blocks destructive `rm -rf` commands targeting dangerous paths (`/`, `~`, `$HOME`, `..`, `.git`). Uses `PreToolUse` / `BeforeTool` events to intercept before execution.

### `test-on-write`

Runs the project's test suite after files are written. Auto-detects the test runner:

- **JS/TS**: `npm test`
- **Python**: `pytest`
- **Go**: `go test ./...`
- **Rust**: `cargo test`
- **Ruby**: `bundle exec rake test`

### `notify-done`

Sends a desktop notification when the agent finishes. Supports macOS (osascript), Linux (notify-send), and Windows WSL (PowerShell).

### `session-context`

Injects git context (branch, recent commits, uncommitted changes) when a session starts.

### `custom`

Use any command you want:

```bash
bash scripts/setup-agent-hooks.sh --hook-type custom --custom-cmd "npx prettier --check ."
```

## Examples

### Example 1: Default Setup (Lint on Edit)

```bash
# Set up lint-on-edit hooks for all agents (default)
bash skills/setup-agent-cli-hooks/scripts/setup-agent-hooks.sh --project-dir /path/to/project
```

### Example 2: Preview Changes

```bash
# Preview what would be created without making changes
bash skills/setup-agent-cli-hooks/scripts/setup-agent-hooks.sh --dry-run
```

### Example 3: Test on Write with User-Level Scope

```bash
# Set up test-on-write with user-level scope (global)
bash skills/setup-agent-cli-hooks/scripts/setup-agent-hooks.sh --scope user --hook-type test-on-write
```

### Example 4: Custom Command

```bash
# Use a custom command
bash skills/setup-agent-cli-hooks/scripts/setup-agent-hooks.sh --hook-type custom --custom-cmd "npx prettier --check ."
```

### Example 5: List Installed Agents

```bash
# Just see which agents are installed
bash skills/setup-agent-cli-hooks/scripts/setup-agent-hooks.sh --list-agents
```

### Example 6: List Available Hooks

```bash
# See all available hook presets
bash skills/setup-agent-cli-hooks/scripts/setup-agent-hooks.sh --list-hooks
```

## Best Practices

1. **Start with `--dry-run`** - Always preview changes before applying them
2. **Choose the right scope** - Use `project` for repo-specific hooks, `user` for global defaults
3. **Test hooks individually** - Verify each hook works before enabling multiple
4. **Check existing configs** - The script merges with existing settings, but review the output
5. **Document custom hooks** - If using `--hook-type custom`, document what the command does

## Agent CLI Documentation

### Claude Code

Hooks are configured in `.claude/settings.json` using the `hooks` object. Supports 14+ lifecycle events including `SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`, `Notification`, `SubagentStart/Stop`, and more. Hooks receive JSON via stdin and can return structured decisions.

**Docs**: https://code.claude.com/docs/en/hooks

### Codex CLI

Codex has limited hook support via the `notify` key in `.codex/config.toml`. Currently only the `agent-turn-complete` event is supported. The community has requested additional hook events.

**Docs**: https://developers.openai.com/codex/config-advanced/

### OpenCode

OpenCode uses TypeScript plugins placed in `.opencode/plugins/`. Plugins export event handlers that receive typed event objects. The plugin system provides `client` and `$` (Bun shell API) utilities.

**Docs**: https://opencode.ai/docs/plugins/

### Gemini CLI

Hooks are configured in `.gemini/settings.json` with a structure similar to Claude Code. Supports `SessionStart`, `BeforeTool`, `AfterTool`, `BeforeAgent`, `AfterAgent`, `Notification`, and more. Hooks receive JSON via stdin.

**Docs**: https://geminicli.com/docs/hooks/

### Amp

Amp uses "toolboxes" — executable scripts that self-describe via the `TOOLBOX_ACTION=describe` pattern. When `TOOLBOX_ACTION=execute`, the script runs the actual tool logic. Set `AMP_TOOLBOX` to the toolboxes directory.

**Docs**: https://ampcode.com/manual

## Troubleshooting

**Problem:** Script says no agents detected
- **Solution**: Install at least one agent CLI (Claude Code, Codex, OpenCode, Gemini, or Amp) or specify a different project directory

**Problem:** Hooks not triggering
- **Solution**: Check that the agent CLI is configured to read from the correct settings file. Some agents require restart after config changes.

**Problem:** `jq` not found warning
- **Solution**: Install jq for JSON manipulation: `sudo apt install jq` (Ubuntu/Debian) or `brew install jq` (macOS). The script works without it but with limited functionality.

**Problem:** Existing settings overwritten
- **Solution**: The script should merge with existing settings. If you experience issues, back up your settings files before running the script.

## Requirements

- **bash** 4.0+
- **jq** (for JSON manipulation — optional but recommended)
- The hook scripts themselves detect and use available linters/test runners
