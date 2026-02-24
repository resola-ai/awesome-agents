#!/usr/bin/env bash
# setup-agent-hooks.sh — Set up hooks for all detected AI coding agent CLIs
# Supports: Claude Code, Codex, OpenCode, Gemini CLI, Amp
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Helpers ─────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[err]${RESET}   $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}── $* ──${RESET}"; }
dim()     { echo -e "${DIM}$*${RESET}"; }

# ── Globals ─────────────────────────────────────────────────────────────────
PROJECT_DIR="${PROJECT_DIR:-.}"
SCOPE="${SCOPE:-project}"            # project | user
HOOK_TYPE="${HOOK_TYPE:-lint-on-edit}" # lint-on-edit | block-rm | test-on-write | notify-done | custom
CUSTOM_HOOK_CMD="${CUSTOM_HOOK_CMD:-}"
DRY_RUN="${DRY_RUN:-false}"
AGENTS_FOUND=()

# ── Usage ───────────────────────────────────────────────────────────────────
usage() {
  cat <<'USAGE'
Usage: setup-agent-hooks.sh [OPTIONS]

Set up hooks for all detected AI coding agent CLIs in your project.

OPTIONS:
  --project-dir DIR    Project directory (default: current directory)
  --scope SCOPE        "project" or "user" (default: project)
  --hook-type TYPE     Hook preset to install (default: lint-on-edit)
  --custom-cmd CMD     Custom command for hook-type=custom
  --dry-run            Show what would be created without writing files
  --list-agents        Detect and list installed agent CLIs, then exit
  --list-hooks         List available hook presets, then exit
  -h, --help           Show this help message

HOOK PRESETS:
  lint-on-edit         Run linter after file edits (PostToolUse / AfterTool)
  block-rm             Block destructive rm commands (PreToolUse / BeforeTool)
  test-on-write        Run tests after file writes (PostToolUse / AfterTool)
  notify-done          Send notification when agent finishes (Stop / Notification)
  session-context      Inject git context on session start (SessionStart)
  custom               Use --custom-cmd to specify a command

EXAMPLES:
  # Set up lint-on-edit hooks for all agents in the current project
  ./setup-agent-hooks.sh

  # Set up test-on-write hooks in a specific project
  ./setup-agent-hooks.sh --project-dir /path/to/project --hook-type test-on-write

  # Preview what would be created
  ./setup-agent-hooks.sh --dry-run

  # Set up user-level hooks
  ./setup-agent-hooks.sh --scope user --hook-type notify-done

  # Use a custom command
  ./setup-agent-hooks.sh --hook-type custom --custom-cmd "npx prettier --check ."
USAGE
}

list_hook_presets() {
  header "Available Hook Presets"
  echo -e "  ${BOLD}lint-on-edit${RESET}       Run linter after file edits"
  echo -e "  ${BOLD}block-rm${RESET}          Block destructive rm -rf commands"
  echo -e "  ${BOLD}test-on-write${RESET}     Run test suite after file writes"
  echo -e "  ${BOLD}notify-done${RESET}       Notification when agent finishes"
  echo -e "  ${BOLD}session-context${RESET}   Inject git context on session start"
  echo -e "  ${BOLD}custom${RESET}            Your own command (use --custom-cmd)"
}

# ── Argument Parsing ────────────────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-dir)  PROJECT_DIR="$2"; shift 2;;
      --scope)        SCOPE="$2"; shift 2;;
      --hook-type)    HOOK_TYPE="$2"; shift 2;;
      --custom-cmd)   CUSTOM_HOOK_CMD="$2"; shift 2;;
      --dry-run)      DRY_RUN=true; shift;;
      --list-agents)  detect_agents; list_agents; exit 0;;
      --list-hooks)   list_hook_presets; exit 0;;
      -h|--help)      usage; exit 0;;
      *)              error "Unknown option: $1"; usage; exit 1;;
    esac
  done

  if [[ ! -d "$PROJECT_DIR" ]]; then
    mkdir -p "$PROJECT_DIR"
  fi
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

  if [[ "$HOOK_TYPE" == "custom" && -z "$CUSTOM_HOOK_CMD" ]]; then
    error "--hook-type custom requires --custom-cmd"
    exit 1
  fi
}

# ── Agent Detection ─────────────────────────────────────────────────────────
detect_agents() {
  AGENTS_FOUND=()

  # Claude Code
  if command -v claude &>/dev/null; then
    AGENTS_FOUND+=("claude-code")
  elif [[ -d "$HOME/.claude" ]]; then
    AGENTS_FOUND+=("claude-code")
  fi

  # Codex CLI
  if command -v codex &>/dev/null; then
    AGENTS_FOUND+=("codex")
  elif [[ -f "$HOME/.codex/config.toml" ]]; then
    AGENTS_FOUND+=("codex")
  fi

  # OpenCode
  if command -v opencode &>/dev/null; then
    AGENTS_FOUND+=("opencode")
  elif [[ -f "$PROJECT_DIR/opencode.json" || -f "$HOME/.config/opencode/opencode.json" ]]; then
    AGENTS_FOUND+=("opencode")
  fi

  # Gemini CLI
  if command -v gemini &>/dev/null; then
    AGENTS_FOUND+=("gemini-cli")
  elif [[ -d "$HOME/.gemini" ]]; then
    AGENTS_FOUND+=("gemini-cli")
  fi

  # Amp
  if command -v amp &>/dev/null; then
    AGENTS_FOUND+=("amp")
  elif [[ -d "$HOME/.config/amp" ]]; then
    AGENTS_FOUND+=("amp")
  fi
}

list_agents() {
  header "Detected Agent CLIs"
  if [[ ${#AGENTS_FOUND[@]} -eq 0 ]]; then
    warn "No agent CLIs detected. The script will still create config files."
    warn "Install an agent CLI and re-run, or configs will be ready when you do."
    return
  fi
  for agent in "${AGENTS_FOUND[@]}"; do
    case "$agent" in
      claude-code) success "Claude Code  — hooks via .claude/settings.json";;
      codex)       success "Codex CLI    — hooks via .codex/config.toml";;
      opencode)    success "OpenCode     — hooks via .opencode/plugins/";;
      gemini-cli)  success "Gemini CLI   — hooks via .gemini/settings.json";;
      amp)         success "Amp          — hooks via .amp/toolboxes/";;
    esac
  done
}

# ── Hook Command Generators ────────────────────────────────────────────────
# Each function returns the shell command string for a given preset.

get_hook_command() {
  local preset="$1"
  case "$preset" in
    lint-on-edit)
      echo '\"$CLAUDE_PROJECT_DIR\"/.agent-hooks/lint-on-edit.sh'
      ;;
    block-rm)
      echo '\"$CLAUDE_PROJECT_DIR\"/.agent-hooks/block-rm.sh'
      ;;
    test-on-write)
      echo '\"$CLAUDE_PROJECT_DIR\"/.agent-hooks/test-on-write.sh'
      ;;
    notify-done)
      echo '\"$CLAUDE_PROJECT_DIR\"/.agent-hooks/notify-done.sh'
      ;;
    session-context)
      echo '\"$CLAUDE_PROJECT_DIR\"/.agent-hooks/session-context.sh'
      ;;
    custom)
      echo "$CUSTOM_HOOK_CMD"
      ;;
  esac
}

# ── Shared Hook Scripts ─────────────────────────────────────────────────────
# These scripts are shared across all agents. Each agent's config points to them.

write_shared_hooks() {
  local hooks_dir="$PROJECT_DIR/.agent-hooks"
  mkdir -p "$hooks_dir"

  # lint-on-edit.sh
  if [[ "$HOOK_TYPE" == "lint-on-edit" || "$HOOK_TYPE" == "all" ]]; then
    write_file "$hooks_dir/lint-on-edit.sh" '#!/usr/bin/env bash
# lint-on-edit.sh — Run linter on edited files
# Works with: Claude Code (PostToolUse), Gemini CLI (AfterTool), OpenCode (plugin), Codex (notify)
set -euo pipefail

INPUT=$(cat)
FILE_PATH=""

# Extract file path from JSON input (Claude Code / Gemini CLI format)
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r ".tool_input.file_path // .tool_input.filePath // empty" 2>/dev/null || true)
fi

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Determine linter based on file extension
EXT="${FILE_PATH##*.}"
case "$EXT" in
  js|jsx|ts|tsx|mjs|cjs)
    if command -v eslint &>/dev/null; then
      eslint --fix "$FILE_PATH" 2>&1 || true
    elif command -v npx &>/dev/null; then
      npx eslint --fix "$FILE_PATH" 2>&1 || true
    fi
    ;;
  py)
    if command -v ruff &>/dev/null; then
      ruff check --fix "$FILE_PATH" 2>&1 || true
    elif command -v flake8 &>/dev/null; then
      flake8 "$FILE_PATH" 2>&1 || true
    fi
    ;;
  go)
    if command -v golangci-lint &>/dev/null; then
      golangci-lint run "$FILE_PATH" 2>&1 || true
    fi
    ;;
  rs)
    if command -v cargo &>/dev/null; then
      cargo clippy 2>&1 || true
    fi
    ;;
  rb)
    if command -v rubocop &>/dev/null; then
      rubocop -a "$FILE_PATH" 2>&1 || true
    fi
    ;;
esac

exit 0
'
  fi

  # block-rm.sh
  if [[ "$HOOK_TYPE" == "block-rm" || "$HOOK_TYPE" == "all" ]]; then
    write_file "$hooks_dir/block-rm.sh" '#!/usr/bin/env bash
# block-rm.sh — Block destructive rm commands
# Works with: Claude Code (PreToolUse), Gemini CLI (BeforeTool)
set -euo pipefail

INPUT=$(cat)
COMMAND=""

if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r ".tool_input.command // empty" 2>/dev/null || true)
fi

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Block rm -rf on dangerous paths
if echo "$COMMAND" | grep -qE "rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|--force\s+)*(\/|~|\$HOME|\.\.|\.git)"; then
  # Return deny decision (Claude Code format, also works for Gemini CLI)
  if command -v jq &>/dev/null; then
    jq -n "{
      hookSpecificOutput: {
        hookEventName: \"PreToolUse\",
        permissionDecision: \"deny\",
        permissionDecisionReason: \"Destructive rm command blocked: $COMMAND\"
      }
    }"
  else
    echo "Blocked: destructive rm command" >&2
    exit 2
  fi
else
  exit 0
fi
'
  fi

  # test-on-write.sh
  if [[ "$HOOK_TYPE" == "test-on-write" || "$HOOK_TYPE" == "all" ]]; then
    write_file "$hooks_dir/test-on-write.sh" '#!/usr/bin/env bash
# test-on-write.sh — Run tests after file writes
# Works with: Claude Code (PostToolUse), Gemini CLI (AfterTool), OpenCode (plugin)
set -euo pipefail

INPUT=$(cat)
FILE_PATH=""

if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r ".tool_input.file_path // .tool_input.filePath // empty" 2>/dev/null || true)
fi

# Skip non-source files
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"
case "$EXT" in
  js|jsx|ts|tsx|mjs|cjs)
    if [[ -f "package.json" ]]; then
      npm test 2>&1 || true
    fi
    ;;
  py)
    if command -v pytest &>/dev/null; then
      pytest --tb=short 2>&1 || true
    elif command -v python3 &>/dev/null; then
      python3 -m pytest --tb=short 2>&1 || true
    fi
    ;;
  go)
    go test ./... 2>&1 || true
    ;;
  rs)
    cargo test 2>&1 || true
    ;;
  rb)
    if command -v bundle &>/dev/null; then
      bundle exec rake test 2>&1 || true
    fi
    ;;
esac

exit 0
'
  fi

  # notify-done.sh
  if [[ "$HOOK_TYPE" == "notify-done" || "$HOOK_TYPE" == "all" ]]; then
    write_file "$hooks_dir/notify-done.sh" '#!/usr/bin/env bash
# notify-done.sh — Send notification when agent finishes
# Works with: Claude Code (Stop/Notification), Gemini CLI (AfterAgent), Codex (notify)
set -euo pipefail

TITLE="Agent Finished"
MESSAGE="The AI coding agent has completed its task."

# macOS
if command -v osascript &>/dev/null; then
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null || true
# Linux with notify-send
elif command -v notify-send &>/dev/null; then
  notify-send "$TITLE" "$MESSAGE" 2>/dev/null || true
# Windows WSL
elif command -v powershell.exe &>/dev/null; then
  powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show(\"$MESSAGE\",\"$TITLE\")" 2>/dev/null || true
# Fallback: terminal bell
else
  echo -e "\a"
fi

exit 0
'
  fi

  # session-context.sh
  if [[ "$HOOK_TYPE" == "session-context" || "$HOOK_TYPE" == "all" ]]; then
    write_file "$hooks_dir/session-context.sh" '#!/usr/bin/env bash
# session-context.sh — Inject git context on session start
# Works with: Claude Code (SessionStart), Gemini CLI (SessionStart)
set -euo pipefail

if ! command -v git &>/dev/null; then
  exit 0
fi

if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "no commits")
STATUS=$(git status --short 2>/dev/null || echo "")

CONTEXT="Git context:
- Branch: $BRANCH
- Recent commits:
$RECENT_COMMITS"

if [[ -n "$STATUS" ]]; then
  CONTEXT="$CONTEXT
- Uncommitted changes:
$STATUS"
fi

# Output as JSON for agents that support additionalContext
if command -v jq &>/dev/null; then
  jq -n --arg ctx "$CONTEXT" "{
    hookSpecificOutput: {
      hookEventName: \"SessionStart\",
      additionalContext: \$ctx
    }
  }"
else
  echo "$CONTEXT"
fi

exit 0
'
  fi
}

# ── File Writer (respects --dry-run) ────────────────────────────────────────
write_file() {
  local path="$1"
  local content="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    dim "  [dry-run] Would create: $path"
    return
  fi

  mkdir -p "$(dirname "$path")"
  echo "$content" > "$path"
  chmod +x "$path" 2>/dev/null || true
}

# Write a file without making it executable
write_config() {
  local path="$1"
  local content="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    dim "  [dry-run] Would create: $path"
    return
  fi

  mkdir -p "$(dirname "$path")"
  echo "$content" > "$path"
}

# ── Claude Code Setup ──────────────────────────────────────────────────────
setup_claude_code() {
  header "Claude Code"

  local settings_dir settings_file
  if [[ "$SCOPE" == "user" ]]; then
    settings_dir="$HOME/.claude"
    settings_file="$settings_dir/settings.json"
  else
    settings_dir="$PROJECT_DIR/.claude"
    settings_file="$settings_dir/settings.json"
  fi

  local hook_cmd
  hook_cmd=$(get_hook_command "$HOOK_TYPE")

  local hooks_json
  case "$HOOK_TYPE" in
    lint-on-edit)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$hook_cmd"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    block-rm)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$hook_cmd"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    test-on-write)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$hook_cmd",
            "async": true,
            "timeout": 300
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    notify-done)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$hook_cmd"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    session-context)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$hook_cmd"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    custom)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$hook_cmd"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
  esac

  # Merge with existing settings if file exists
  if [[ "$DRY_RUN" != "true" && -f "$settings_file" ]] && command -v jq &>/dev/null; then
    local existing
    existing=$(cat "$settings_file")
    local merged
    merged=$(echo "$existing" | jq --argjson new "$hooks_json" '. * $new')
    write_config "$settings_file" "$merged"
    success "Merged hooks into existing $settings_file"
  else
    write_config "$settings_file" "$hooks_json"
    [[ "$DRY_RUN" == "true" ]] || success "Created $settings_file"
  fi
}

# ── Codex CLI Setup ────────────────────────────────────────────────────────
setup_codex() {
  header "Codex CLI"

  local config_dir config_file
  if [[ "$SCOPE" == "user" ]]; then
    config_dir="$HOME/.codex"
    config_file="$config_dir/config.toml"
  else
    config_dir="$PROJECT_DIR/.codex"
    config_file="$config_dir/config.toml"
  fi

  # Codex has limited hook support — only the notify key for agent-turn-complete
  local notify_cmd
  case "$HOOK_TYPE" in
    notify-done)
      notify_cmd="[\"bash\", \"-c\", \"$PROJECT_DIR/.agent-hooks/notify-done.sh\"]"
      ;;
    *)
      # For other hook types, use the notify mechanism to run the hook script
      local hook_script
      hook_script=$(get_hook_command "$HOOK_TYPE" | sed 's|\\"\$CLAUDE_PROJECT_DIR\\"|.|g')
      notify_cmd="[\"bash\", \"-c\", \"$PROJECT_DIR/.agent-hooks/notify-done.sh\"]"
      ;;
  esac

  local toml_content
  toml_content="# Codex CLI hooks configuration
# Note: Codex currently only supports the 'notify' hook (agent-turn-complete event).
# For more hook events, see: https://github.com/openai/codex/discussions/2150

notify = [\"bash\", \"-c\", \"$PROJECT_DIR/.agent-hooks/notify-done.sh\"]
"

  if [[ "$DRY_RUN" != "true" && -f "$config_file" ]]; then
    if grep -q "^notify" "$config_file" 2>/dev/null; then
      warn "Codex config already has a notify key in $config_file"
      warn "Skipping to avoid overwriting. Edit manually if needed."
    else
      # Prepend notify to existing config (root keys must come before tables)
      local existing
      existing=$(cat "$config_file")
      write_config "$config_file" "$toml_content
$existing"
      success "Added notify hook to existing $config_file"
    fi
  else
    write_config "$config_file" "$toml_content"
    [[ "$DRY_RUN" == "true" ]] || success "Created $config_file"
  fi

  dim "  Note: Codex hooks are limited to 'notify' on agent-turn-complete."
  dim "  For full lifecycle hooks, consider using Claude Code or Gemini CLI."
}

# ── OpenCode Setup ──────────────────────────────────────────────────────────
setup_opencode() {
  header "OpenCode"

  local plugin_dir
  if [[ "$SCOPE" == "user" ]]; then
    plugin_dir="$HOME/.config/opencode/plugins"
  else
    plugin_dir="$PROJECT_DIR/.opencode/plugins"
  fi

  local hook_script_path="$PROJECT_DIR/.agent-hooks"

  # OpenCode uses TypeScript plugins for hooks
  local event_type hook_filter
  case "$HOOK_TYPE" in
    lint-on-edit)
      event_type="tool.execute.after"
      hook_filter='["write", "edit"]'
      ;;
    test-on-write)
      event_type="tool.execute.after"
      hook_filter='["write"]'
      ;;
    notify-done)
      event_type="session.idle"
      hook_filter='[]'
      ;;
    block-rm|session-context|custom)
      event_type="tool.execute.after"
      hook_filter='[]'
      ;;
  esac

  local plugin_content
  plugin_content="import type { Plugin } from \"@opencode-ai/plugin\";
import { execSync } from \"child_process\";
import path from \"path\";

// Auto-generated by setup-agent-hooks.sh
// Hook type: $HOOK_TYPE

export const AgentHookPlugin: Plugin = async ({ client, \$ }) => {
  const hooksDir = path.resolve(\"$hook_script_path\");

  return {
    event: async ({ event }) => {
      // $HOOK_TYPE hook
      if (event.type === \"$event_type\") {
        try {
          const scriptName = \"$(basename "$(get_hook_command "$HOOK_TYPE" | tr -d '\\\"' | sed 's|\$CLAUDE_PROJECT_DIR/.agent-hooks/||')")\";
          const scriptPath = path.join(hooksDir, scriptName);
          const input = JSON.stringify(event);
          execSync(\`echo '\${input}' | bash \${scriptPath}\`, {
            cwd: process.cwd(),
            stdio: [\"pipe\", \"pipe\", \"pipe\"],
            timeout: 60000,
          });
        } catch (err) {
          // Hook errors are non-fatal
          client.app.log(\`Hook error: \${err}\`);
        }
      }
    },
  };
};

export default AgentHookPlugin;
"

  write_config "$plugin_dir/agent-hooks.ts" "$plugin_content"
  [[ "$DRY_RUN" == "true" ]] || success "Created OpenCode plugin at $plugin_dir/agent-hooks.ts"
  dim "  OpenCode uses TypeScript plugins instead of JSON hooks."
  dim "  The plugin wraps the shared hook scripts in .agent-hooks/."
}

# ── Gemini CLI Setup ───────────────────────────────────────────────────────
setup_gemini_cli() {
  header "Gemini CLI"

  local settings_dir settings_file
  if [[ "$SCOPE" == "user" ]]; then
    settings_dir="$HOME/.gemini"
    settings_file="$settings_dir/settings.json"
  else
    settings_dir="$PROJECT_DIR/.gemini"
    settings_file="$settings_dir/settings.json"
  fi

  local hook_cmd
  hook_cmd=$(get_hook_command "$HOOK_TYPE")
  # Replace $CLAUDE_PROJECT_DIR with $GEMINI_PROJECT_DIR for Gemini
  hook_cmd=$(echo "$hook_cmd" | sed 's/\$CLAUDE_PROJECT_DIR/\$GEMINI_PROJECT_DIR/g')

  local hooks_json
  case "$HOOK_TYPE" in
    lint-on-edit)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "AfterTool": [
      {
        "matcher": "write_.*|edit_.*",
        "hooks": [
          {
            "name": "lint-on-edit",
            "type": "command",
            "command": "$hook_cmd",
            "timeout": 30000,
            "description": "Run linter after file edits"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    block-rm)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "BeforeTool": [
      {
        "matcher": "execute_command|shell",
        "hooks": [
          {
            "name": "block-rm",
            "type": "command",
            "command": "$hook_cmd",
            "timeout": 5000,
            "description": "Block destructive rm commands"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    test-on-write)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "AfterTool": [
      {
        "matcher": "write_.*",
        "hooks": [
          {
            "name": "test-on-write",
            "type": "command",
            "command": "$hook_cmd",
            "timeout": 300000,
            "description": "Run tests after file writes"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    notify-done)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "AfterAgent": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "notify-done",
            "type": "command",
            "command": "$hook_cmd",
            "description": "Notify when agent finishes"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    session-context)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "session-context",
            "type": "command",
            "command": "$hook_cmd",
            "description": "Inject git context on session start"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
    custom)
      hooks_json=$(cat <<HOOKJSON
{
  "hooks": {
    "AfterTool": [
      {
        "matcher": "*",
        "hooks": [
          {
            "name": "custom-hook",
            "type": "command",
            "command": "$hook_cmd",
            "description": "Custom hook"
          }
        ]
      }
    ]
  }
}
HOOKJSON
)
      ;;
  esac

  if [[ "$DRY_RUN" != "true" && -f "$settings_file" ]] && command -v jq &>/dev/null; then
    local existing
    existing=$(cat "$settings_file")
    local merged
    merged=$(echo "$existing" | jq --argjson new "$hooks_json" '. * $new')
    write_config "$settings_file" "$merged"
    success "Merged hooks into existing $settings_file"
  else
    write_config "$settings_file" "$hooks_json"
    [[ "$DRY_RUN" == "true" ]] || success "Created $settings_file"
  fi
}

# ── Amp Setup ──────────────────────────────────────────────────────────────
setup_amp() {
  header "Amp"

  local toolbox_dir
  if [[ "$SCOPE" == "user" ]]; then
    toolbox_dir="$HOME/.config/amp/toolboxes"
  else
    toolbox_dir="$PROJECT_DIR/.amp/toolboxes"
  fi

  # Amp uses "toolboxes" — executable scripts that describe themselves
  # When TOOLBOX_ACTION=describe, print JSON description
  # When TOOLBOX_ACTION=execute, run the tool

  local tool_name tool_desc
  case "$HOOK_TYPE" in
    lint-on-edit)   tool_name="lint-check";     tool_desc="Run linter on a file after editing";;
    block-rm)       tool_name="safe-rm-check";  tool_desc="Check if an rm command is safe to run";;
    test-on-write)  tool_name="run-tests";      tool_desc="Run the project test suite";;
    notify-done)    tool_name="notify";         tool_desc="Send a desktop notification";;
    session-context) tool_name="git-context";   tool_desc="Get current git context";;
    custom)         tool_name="custom-hook";    tool_desc="Run custom hook command";;
  esac

  local hook_script
  hook_script=$(get_hook_command "$HOOK_TYPE" | sed 's|\\"\$CLAUDE_PROJECT_DIR\\"|.|' | tr -d '\\"')

  local toolbox_content
  toolbox_content="#!/usr/bin/env bash
# Amp toolbox: $tool_name
# Auto-generated by setup-agent-hooks.sh
set -euo pipefail

ACTION=\"\${TOOLBOX_ACTION:-execute}\"

case \"\$ACTION\" in
  describe)
    cat <<'DESC'
{
  \"name\": \"$tool_name\",
  \"description\": \"$tool_desc\",
  \"parameters\": {
    \"type\": \"object\",
    \"properties\": {
      \"input\": {
        \"type\": \"string\",
        \"description\": \"JSON input from the agent\"
      }
    }
  }
}
DESC
    ;;
  execute)
    # Forward to shared hook script
    SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"
    PROJECT_ROOT=\"\$(cd \"\$SCRIPT_DIR/../..\" && pwd)\"
    if [[ -n \"\${1:-}\" ]]; then
      echo \"\$1\" | bash \"\$PROJECT_ROOT/.agent-hooks/$(basename "$hook_script")\"
    else
      bash \"\$PROJECT_ROOT/.agent-hooks/$(basename "$hook_script")\"
    fi
    ;;
esac
"

  write_file "$toolbox_dir/$tool_name" "$toolbox_content"
  [[ "$DRY_RUN" == "true" ]] || success "Created Amp toolbox at $toolbox_dir/$tool_name"
  dim "  Set AMP_TOOLBOX=$toolbox_dir to enable."
  dim "  Amp uses toolboxes (executable scripts) instead of JSON hooks."
}

# ── .gitignore update ──────────────────────────────────────────────────────
update_gitignore() {
  if [[ "$SCOPE" != "project" ]]; then
    return
  fi

  local gitignore="$PROJECT_DIR/.gitignore"

  # Check if .agent-hooks is already in .gitignore
  if [[ -f "$gitignore" ]] && grep -qF ".agent-hooks" "$gitignore" 2>/dev/null; then
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    dim "  [dry-run] Would update .gitignore"
    return
  fi

  # The hooks directory is intended to be committed (shared with team)
  # But local settings may vary — add a note
  info "Hook scripts in .agent-hooks/ are designed to be committed to your repo."
  info "Agent-specific config files (.claude/, .gemini/, etc.) can also be committed."
}

# ── Summary ─────────────────────────────────────────────────────────────────
print_summary() {
  header "Summary"
  echo -e "  Project:    ${BOLD}$PROJECT_DIR${RESET}"
  echo -e "  Scope:      ${BOLD}$SCOPE${RESET}"
  echo -e "  Hook type:  ${BOLD}$HOOK_TYPE${RESET}"
  echo -e "  Agents:     ${BOLD}${AGENTS_FOUND[*]:-none detected (configs still created)}${RESET}"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "\n  ${YELLOW}Dry run — no files were written.${RESET}"
    echo -e "  Remove --dry-run to create the files."
  else
    echo ""
    echo -e "  ${GREEN}Hook scripts:${RESET}  $PROJECT_DIR/.agent-hooks/"
    echo -e ""
    echo -e "  ${BOLD}Files created:${RESET}"
    [[ -f "$PROJECT_DIR/.claude/settings.json" ]]      && echo "    - .claude/settings.json       (Claude Code)"
    [[ -f "$PROJECT_DIR/.codex/config.toml" ]]          && echo "    - .codex/config.toml          (Codex CLI)"
    [[ -d "$PROJECT_DIR/.opencode/plugins" ]]           && echo "    - .opencode/plugins/           (OpenCode)"
    [[ -f "$PROJECT_DIR/.gemini/settings.json" ]]       && echo "    - .gemini/settings.json       (Gemini CLI)"
    [[ -d "$PROJECT_DIR/.amp/toolboxes" ]]              && echo "    - .amp/toolboxes/              (Amp)"
    echo ""
    echo -e "  ${DIM}Restart your agent CLI to pick up the new hooks.${RESET}"
  fi
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
  echo -e "${BOLD}${CYAN}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║   Agent CLI Hooks Setup                  ║"
  echo "  ║   Claude Code · Codex · OpenCode         ║"
  echo "  ║   Gemini CLI · Amp                       ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${RESET}"

  parse_args "$@"
  detect_agents
  list_agents

  header "Setting up '$HOOK_TYPE' hooks"

  # Write shared hook scripts
  write_shared_hooks

  # Set up each agent
  setup_claude_code
  setup_codex
  setup_opencode
  setup_gemini_cli
  setup_amp

  # Update gitignore
  update_gitignore

  # Print summary
  print_summary
}

main "$@"
