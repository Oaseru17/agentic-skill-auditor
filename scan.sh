#!/usr/bin/env bash

# ─────────────────────────────────────────────────────────────
# Agentic Engineering Audit Skill
# Scans your machine and project for AI engineering maturity.
# Scores you 0-900 across 9 categories.
# Built by oaseru.dev
# ─────────────────────────────────────────────────────────────

VERSION="1.0.0"
SUBMIT_URL="https://oaseru.dev/api/scores"

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
PINK='\033[38;5;197m'

# ── Category scores (indexed by position) ──────────────────
# 0=context 1=mcp 2=skills 3=memory 4=hooks
# 5=pipeline 6=multimodel 7=background 8=orchestration
CAT_SCORES="0 0 0 0 0 0 0 0 0"
CAT_WEIGHTS="1.5 1.0 1.0 1.0 1.5 1.0 1.0 0.5 0.5"
CAT_NAMES="Context_Setup Tool_Connections Skills_and_Commands Memory_and_Compounding Feedback_Loops_and_Hooks Pipeline_Headless Multi-Agent_Multi-Model Background_Always-On Orchestration_Swarm"
CAT_DISPLAY_NAMES="Context Setup|Tool Connections (MCP)|Skills & Commands|Memory & Compounding|Feedback Loops & Hooks|Pipeline / Headless|Multi-Agent / Multi-Model|Background / Always-On|Orchestration / Swarm"

set_score() {
  local idx=$1 val=$2
  local i=0
  local new_scores=""
  for s in $CAT_SCORES; do
    if [ $i -eq $idx ]; then
      new_scores="$new_scores $val"
    else
      new_scores="$new_scores $s"
    fi
    i=$((i + 1))
  done
  CAT_SCORES=$(echo "$new_scores" | sed 's/^ //')
}

get_score() {
  echo "$CAT_SCORES" | cut -d' ' -f$(($1 + 1))
}

get_weight() {
  echo "$CAT_WEIGHTS" | cut -d' ' -f$(($1 + 1))
}

get_display_name() {
  echo "$CAT_DISPLAY_NAMES" | cut -d'|' -f$(($1 + 1))
}

SCAN_DIR="${1:-.}"
SCAN_DIR="$(cd "$SCAN_DIR" 2>/dev/null && pwd)" || SCAN_DIR="$(pwd)"
HOME_DIR="$HOME"

# ── Helpers ─────────────────────────────────────────────────
hr() {
  printf "${DIM}────────────────────────────────────────────────────────────${RESET}\n"
}

header() {
  printf "\n${PINK}${BOLD}%s${RESET}\n" "$1"
  hr
}

found() {
  printf "  ${GREEN}✓${RESET} %s\n" "$1"
}

not_found() {
  printf "  ${DIM}✗ %s${RESET}\n" "$1"
}

detail() {
  printf "  ${DIM}  → %s${RESET}\n" "$1"
}

bar() {
  local score=$1
  local width=20
  local filled=$((score * width / 100))
  local empty=$((width - filled))
  local color="$RED"
  if [ "$score" -ge 70 ]; then color="$GREEN"
  elif [ "$score" -ge 40 ]; then color="$YELLOW"
  fi
  printf "${color}"
  for i in $(seq 1 $filled); do printf "█"; done
  printf "${DIM}"
  for i in $(seq 1 $empty); do printf "░"; done
  printf "${RESET}"
}

count_mcp_servers() {
  local file="$1"
  if [ -f "$file" ] && command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    d = json.load(open('$file'))
    servers = d.get('mcpServers', d.get('servers', {}))
    print(len(servers) if isinstance(servers, dict) else 0)
except: print(0)
" 2>/dev/null
  else
    echo 0
  fi
}

# Check ~/.claude.json projects structure for MCP servers
count_project_mcp_servers() {
  local file="$1"
  local scan_dir="$2"
  if [ -f "$file" ] && command -v python3 &>/dev/null; then
    python3 -c "
import json, os
try:
    d = json.load(open('$file'))
    projects = d.get('projects', {})
    total = 0
    names = []
    for path, cfg in projects.items():
        if not isinstance(cfg, dict): continue
        servers = cfg.get('mcpServers', {})
        if isinstance(servers, dict) and len(servers) > 0:
            names.extend(servers.keys())
        elif isinstance(servers, list) and len(servers) > 0:
            names.extend(servers)
    unique = list(set(names))
    print(len(unique))
    for n in unique:
        print(n)
except: print(0)
" 2>/dev/null
  else
    echo 0
  fi
}

# ── Banner ──────────────────────────────────────────────────
clear 2>/dev/null || true
printf "\n"
printf "${PINK}${BOLD}"
printf "   ╔══════════════════════════════════════════════╗\n"
printf "   ║     AGENTIC SKILL AUDITOR  v%s          ║\n" "$VERSION"
printf "   ║          oaseru.dev/audit                    ║\n"
printf "   ╚══════════════════════════════════════════════╝\n"
printf "${RESET}\n"
printf "  ${DIM}Scanning: %s${RESET}\n" "$SCAN_DIR"
printf "  ${DIM}Home:     %s${RESET}\n" "$HOME_DIR"
printf "\n"

# ═════════════════════════════════════════════════════════════
# CATEGORY 1: CONTEXT SETUP (weight 1.5x)
# ═════════════════════════════════════════════════════════════
# L1 (Grounded): A rules file exists. You have told the AI
# about your stack, your standards, and your project structure.
# The AI has baseline context before you type a single prompt.
#
# L1 is the single highest-leverage step. A 20-minute
# investment in a context file saves hours every week.
# ═════════════════════════════════════════════════════════════
header "1. Context Setup (L1: Grounded)"
printf "  ${DIM}Do you give your AI baseline context about your project?${RESET}\n"
printf "  ${DIM}Context files tell the agent your stack, conventions, and rules${RESET}\n"
printf "  ${DIM}before you type a single prompt. This is the single highest-leverage${RESET}\n"
printf "  ${DIM}step: a 20-minute investment saves hours every week.${RESET}\n\n"

context_score=0
context_files_found=0
context_quality=0

for f in "CLAUDE.md" ".claude/CLAUDE.md" ".cursorrules" ".cursorignore" \
         ".github/copilot-instructions.md" ".windsurfrules" ".aider.conf.yml"; do
  if [ -f "$SCAN_DIR/$f" ]; then
    lines=$(wc -l < "$SCAN_DIR/$f" 2>/dev/null || echo 0)
    lines=$(echo "$lines" | tr -d ' ')
    found "$f ($lines lines)"
    context_files_found=$((context_files_found + 1))
    if [ "$lines" -gt 20 ]; then
      context_quality=$((context_quality + 1))
      detail "Well-configured (>20 lines)"
    fi
  else
    not_found "$f"
  fi
done

if [ -f "$HOME_DIR/.claude/CLAUDE.md" ]; then
  lines=$(wc -l < "$HOME_DIR/.claude/CLAUDE.md" 2>/dev/null | tr -d ' ' || echo 0)
  found "~/.claude/CLAUDE.md (global, $lines lines)"
  context_files_found=$((context_files_found + 1))
  if [ "$lines" -gt 20 ]; then context_quality=$((context_quality + 1)); fi
else
  not_found "~/.claude/CLAUDE.md (global)"
fi

if [ $context_files_found -eq 0 ]; then
  context_score=0
elif [ $context_files_found -eq 1 ] && [ $context_quality -eq 0 ]; then
  context_score=30
elif [ $context_files_found -eq 1 ]; then
  context_score=50
elif [ $context_quality -ge 2 ]; then
  context_score=100
else
  context_score=70
fi

set_score 0 $context_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$context_score"

# ═════════════════════════════════════════════════════════════
# CATEGORY 2: TOOL CONNECTIONS / MCP (weight 1.0x)
# ═════════════════════════════════════════════════════════════
# L2 (Connected): Your AI agent is connected to real data
# sources. MCP servers, database connections, API docs, and
# live systems feed context into the agent automatically.
# Context is dynamic, not just static files. The agent
# understands your actual system state.
# ═════════════════════════════════════════════════════════════
header "2. Tool Connections / MCP (L2: Connected)"
printf "  ${DIM}Is your AI connected to real data sources?${RESET}\n"
printf "  ${DIM}MCP (Model Context Protocol) servers let the agent query${RESET}\n"
printf "  ${DIM}databases, access GitHub, read docs, and interact with${RESET}\n"
printf "  ${DIM}external services through a single, open standard.${RESET}\n\n"

mcp_score=0
mcp_server_count=0
mcp_configs_found=0

# Claude Code: check ~/.claude.json projects structure (where MCP servers live)
if [ -f "$HOME_DIR/.claude.json" ]; then
  project_mcp_output=$(count_project_mcp_servers "$HOME_DIR/.claude.json" "$SCAN_DIR")
  project_mcp_count=$(echo "$project_mcp_output" | head -1)
  if [ "$project_mcp_count" -gt 0 ] 2>/dev/null; then
    found "Claude Code MCP servers ($project_mcp_count)"
    echo "$project_mcp_output" | tail -n +2 | while read -r srv; do
      [ -n "$srv" ] && detail "$srv"
    done
    mcp_server_count=$((mcp_server_count + project_mcp_count))
    mcp_configs_found=$((mcp_configs_found + 1))
  fi
  # Also check top-level mcpServers
  n=$(count_mcp_servers "$HOME_DIR/.claude.json")
  if [ "$n" -gt 0 ]; then
    found "~/.claude.json top-level ($n MCP servers)"
    mcp_server_count=$((mcp_server_count + n))
    mcp_configs_found=$((mcp_configs_found + 1))
  fi
fi

# Claude Code: project-level settings
if [ -f "$SCAN_DIR/.claude/settings.json" ]; then
  n=$(count_mcp_servers "$SCAN_DIR/.claude/settings.json")
  if [ "$n" -gt 0 ]; then
    found ".claude/settings.json ($n MCP servers)"
    mcp_server_count=$((mcp_server_count + n))
    mcp_configs_found=$((mcp_configs_found + 1))
  fi
fi

if [ -f "$SCAN_DIR/.mcp.json" ]; then
  n=$(count_mcp_servers "$SCAN_DIR/.mcp.json")
  found ".mcp.json ($n servers)"
  mcp_server_count=$((mcp_server_count + n))
  mcp_configs_found=$((mcp_configs_found + 1))
else
  not_found ".mcp.json"
fi

for mcp_path in "$HOME_DIR/.cursor/mcp.json" "$SCAN_DIR/.cursor/mcp.json"; do
  if [ -f "$mcp_path" ]; then
    n=$(count_mcp_servers "$mcp_path")
    found "$(basename "$(dirname "$mcp_path")")/mcp.json ($n servers)"
    mcp_server_count=$((mcp_server_count + n))
    mcp_configs_found=$((mcp_configs_found + 1))
  fi
done

if [ -f "$SCAN_DIR/.vscode/settings.json" ]; then
  if grep -q "mcp" "$SCAN_DIR/.vscode/settings.json" 2>/dev/null; then
    found ".vscode/settings.json (has MCP config)"
    mcp_configs_found=$((mcp_configs_found + 1))
  fi
fi

if [ $mcp_server_count -eq 0 ]; then
  mcp_score=0
elif [ $mcp_server_count -le 2 ]; then
  mcp_score=50
else
  mcp_score=100
fi

set_score 1 $mcp_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$mcp_score"

# ═════════════════════════════════════════════════════════════
# CATEGORY 3: SKILLS & COMMANDS (weight 1.0x)
# ═════════════════════════════════════════════════════════════
# L3 (Skilled): You have three or more custom skills. These
# are repeatable, documented workflows that the agent can
# execute without re-explanation. Skills cover PR review,
# deployment, testing, documentation. Workflows are consistent
# and auditable.
# ═════════════════════════════════════════════════════════════
header "3. Skills & Commands (L3: Skilled)"
printf "  ${DIM}Do you have repeatable, documented workflows your agent${RESET}\n"
printf "  ${DIM}can execute from a single command? Skills turn one-off${RESET}\n"
printf "  ${DIM}prompts into reliable, auditable processes. At L3 you need${RESET}\n"
printf "  ${DIM}three or more covering PR review, deployment, testing, etc.${RESET}\n\n"

skills_score=0
skill_count=0

if [ -d "$SCAN_DIR/.claude/skills" ]; then
  skill_files=$(find "$SCAN_DIR/.claude/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$skill_files" -gt 0 ]; then
    found ".claude/skills/ ($skill_files SKILL.md files)"
    skill_count=$((skill_count + skill_files))
    find "$SCAN_DIR/.claude/skills" -name "SKILL.md" 2>/dev/null | head -5 | while read -r sf; do
      skill_name=$(basename "$(dirname "$sf")")
      detail "$skill_name"
    done
    remaining=$((skill_files - 5))
    if [ $remaining -gt 0 ]; then
      detail "... and $remaining more"
    fi
  else
    not_found ".claude/skills/ (directory exists but no SKILL.md files)"
  fi
else
  not_found ".claude/skills/"
fi

if [ -d "$HOME_DIR/.claude/skills" ]; then
  global_skills=$(find "$HOME_DIR/.claude/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$global_skills" -gt 0 ]; then
    found "~/.claude/skills/ ($global_skills global skills)"
    skill_count=$((skill_count + global_skills))
  fi
fi

if [ -d "$SCAN_DIR/.claude/commands" ]; then
  cmd_files=$(find "$SCAN_DIR/.claude/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$cmd_files" -gt 0 ]; then
    found ".claude/commands/ ($cmd_files custom commands)"
    skill_count=$((skill_count + cmd_files))
  fi
fi

if [ $skill_count -eq 0 ]; then
  skills_score=0
elif [ $skill_count -le 2 ]; then
  skills_score=50
else
  skills_score=100
fi

set_score 2 $skills_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$skills_score"

# ═════════════════════════════════════════════════════════════
# CATEGORY 4: MEMORY & COMPOUNDING (weight 1.0x)
# ═════════════════════════════════════════════════════════════
# L4 (Compounding Architect): You operate in a continuous loop:
# Plan, Delegate, Assess, Codify. Every task feeds learnings
# back into the system. Memory files persist knowledge across
# sessions. Knowledge files capture domain-specific learnings
# inside each skill.
# ═════════════════════════════════════════════════════════════
header "4. Memory & Compounding (L4: Compounding Architect)"
printf "  ${DIM}Does your AI retain and build on knowledge across sessions?${RESET}\n"
printf "  ${DIM}At L4 you operate in a continuous loop: Plan, Delegate,${RESET}\n"
printf "  ${DIM}Assess, Codify. Every task feeds learnings back into the${RESET}\n"
printf "  ${DIM}system. Your AI gets smarter with every interaction.${RESET}\n\n"

memory_score=0
memory_files=0
has_memory_index=false
has_knowledge=false

if [ -d "$HOME_DIR/.claude/projects" ]; then
  memory_dirs=$(find "$HOME_DIR/.claude/projects" -type d -name "memory" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$memory_dirs" -gt 0 ]; then
    found "~/.claude/projects/ ($memory_dirs memory directories)"
    memory_files=$(find "$HOME_DIR/.claude/projects" -path "*/memory/*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$memory_files" -gt 0 ]; then
      detail "$memory_files memory files across projects"
    fi
    if find "$HOME_DIR/.claude/projects" -name "MEMORY.md" 2>/dev/null | grep -q .; then
      has_memory_index=true
      detail "MEMORY.md index found"
    fi
  else
    not_found "~/.claude/projects/*/memory/ (no memory directories)"
  fi
else
  not_found "~/.claude/projects/"
fi

if [ -d "$SCAN_DIR/.claude/skills" ]; then
  knowledge_count=$(find "$SCAN_DIR/.claude/skills" -name "knowledge.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$knowledge_count" -gt 0 ]; then
    found "$knowledge_count knowledge.md files in skills"
    has_knowledge=true
  fi
fi

state_files=$(find "$SCAN_DIR" -maxdepth 3 -name "project-state.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$state_files" -gt 0 ]; then
  found "$state_files project-state.md file(s)"
fi

if [ $memory_files -eq 0 ] && [ "$has_knowledge" = "false" ]; then
  memory_score=0
elif [ $memory_files -le 3 ] && [ "$has_memory_index" = "false" ]; then
  memory_score=30
elif [ "$has_memory_index" = "true" ] && [ $memory_files -le 5 ]; then
  memory_score=50
elif [ "$has_memory_index" = "true" ] && [ "$has_knowledge" = "true" ]; then
  memory_score=100
else
  memory_score=70
fi

set_score 3 $memory_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$memory_score"

# ═════════════════════════════════════════════════════════════
# CATEGORY 5: FEEDBACK LOOPS & HOOKS (weight 1.5x)
# ═════════════════════════════════════════════════════════════
# L5 (Harness Builder): You have built automated feedback loops
# that create backpressure on the agent. Tests, linters, type
# checkers, and hooks act as guardrails that force the agent
# to self-correct. Backpressure is the key insight: you are
# not reviewing manually, systems do it for you.
#
# Four hook types at lifecycle events:
#   PreSession: load context, check pending work
#   PostTask: run quality checks, enforce review
#   PostToolUse: gate destructive actions
#   PostApproval: capture learnings, update docs
# ═════════════════════════════════════════════════════════════
header "5. Feedback Loops & Hooks (L5: Harness Builder)"
printf "  ${DIM}Do you have automated guardrails that force your agent${RESET}\n"
printf "  ${DIM}to self-correct? At L5, backpressure is the key insight:${RESET}\n"
printf "  ${DIM}you are not reviewing the agent's work manually, you have${RESET}\n"
printf "  ${DIM}built systems (hooks, tests, linters) that do it for you.${RESET}\n\n"

hooks_score=0
has_ai_hooks=false
has_git_hooks=false
has_quality_tools=false

for settings_file in "$SCAN_DIR/.claude/settings.json" "$HOME_DIR/.claude/settings.json"; do
  if [ -f "$settings_file" ]; then
    if grep -q '"hooks"' "$settings_file" 2>/dev/null; then
      has_ai_hooks=true
      display_path=$(echo "$settings_file" | sed "s|$HOME_DIR|~|")
      found "$display_path has hooks configured"
      for hook_type in "PreToolUse" "PostToolUse" "PreSession" "PostSession" \
                       "PreTask" "PostTask" "Notification"; do
        if grep -q "$hook_type" "$settings_file" 2>/dev/null; then
          detail "$hook_type hook active"
        fi
      done
    fi
  fi
done

if [ -d "$SCAN_DIR/hooks" ]; then
  hook_scripts=$(find "$SCAN_DIR/hooks" -type f \( -name "*.sh" -o -name "*.js" -o -name "*.py" \) 2>/dev/null | wc -l | tr -d ' ')
  if [ "$hook_scripts" -gt 0 ]; then
    found "hooks/ directory ($hook_scripts scripts)"
    has_ai_hooks=true
  fi
fi

if [ -d "$SCAN_DIR/.husky" ]; then
  found ".husky/ (Git hooks via Husky)"
  has_git_hooks=true
fi

if [ -d "$SCAN_DIR/.git/hooks" ]; then
  active_hooks=$(find "$SCAN_DIR/.git/hooks" -type f ! -name "*.sample" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$active_hooks" -gt 0 ]; then
    found ".git/hooks/ ($active_hooks active hooks)"
    has_git_hooks=true
  fi
fi

if [ -f "$SCAN_DIR/.pre-commit-config.yaml" ]; then
  found ".pre-commit-config.yaml"
  has_git_hooks=true
fi

for tool in ".eslintrc" ".eslintrc.js" ".eslintrc.json" "eslint.config.js" "eslint.config.mjs" \
            ".prettierrc" ".prettierrc.json" "prettier.config.js" \
            "tsconfig.json" "biome.json"; do
  if [ -f "$SCAN_DIR/$tool" ]; then
    has_quality_tools=true
    break
  fi
done

if [ "$has_quality_tools" = "true" ]; then
  found "Quality tools detected (linter/formatter/type checker)"
fi

if [ -f "$SCAN_DIR/package.json" ]; then
  if grep -q "lint-staged" "$SCAN_DIR/package.json" 2>/dev/null; then
    found "lint-staged configured in package.json"
    has_git_hooks=true
  fi
fi

if [ "$has_ai_hooks" = "true" ]; then
  hooks_score=100
elif [ "$has_git_hooks" = "true" ] && [ "$has_quality_tools" = "true" ]; then
  hooks_score=50
elif [ "$has_git_hooks" = "true" ] || [ "$has_quality_tools" = "true" ]; then
  hooks_score=30
else
  hooks_score=0
fi

set_score 4 $hooks_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$hooks_score"

# ═════════════════════════════════════════════════════════════
# CATEGORY 6: PIPELINE / HEADLESS (weight 1.0x)
# ═════════════════════════════════════════════════════════════
# L6 (Pipeline Engineer): The AI runs in headless mode. Scripts
# call the agent, not humans. CI pipelines trigger agent
# workflows. The agent is part of your infrastructure, not
# just your IDE. Human involvement is supervisory, not
# operational.
# ═════════════════════════════════════════════════════════════
header "6. Pipeline / Headless (L6: Pipeline Engineer)"
printf "  ${DIM}Does your AI run as part of your infrastructure?${RESET}\n"
printf "  ${DIM}At L6, scripts call the agent, not humans. CI pipelines${RESET}\n"
printf "  ${DIM}trigger agent workflows. The agent is part of your build${RESET}\n"
printf "  ${DIM}and deploy process, not just your IDE.${RESET}\n\n"

pipeline_score=0
has_ci_ai=false
has_headless=false

if [ -d "$SCAN_DIR/.github/workflows" ]; then
  ai_refs=$(grep -rl "claude\|anthropic\|copilot\|cursor\|openai\|ai-agent" \
    "$SCAN_DIR/.github/workflows" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ai_refs" -gt 0 ]; then
    found ".github/workflows/ references AI tools ($ai_refs files)"
    has_ci_ai=true
  else
    found ".github/workflows/ exists (no AI integration)"
  fi
fi

for ci_file in ".gitlab-ci.yml" "Jenkinsfile" ".circleci/config.yml"; do
  if [ -f "$SCAN_DIR/$ci_file" ]; then
    if grep -qi "claude\|anthropic\|copilot\|cursor\|openai" "$SCAN_DIR/$ci_file" 2>/dev/null; then
      found "$ci_file references AI tools"
      has_ci_ai=true
    fi
  fi
done

script_refs=$(grep -rl 'claude.*--print\|claude.*-p \|claude.*--dangerously\|claude.*--model\|claude.*--allowedTools' "$SCAN_DIR" \
  --include="*.sh" --include="*.py" --include="*.js" --include="*.ts" \
  --include="Makefile" --include="*.yaml" --include="*.yml" \
  2>/dev/null | grep -v node_modules | grep -v .git | wc -l | tr -d ' ')

if [ "$script_refs" -gt 0 ]; then
  found "Scripts invoke AI agents headlessly ($script_refs files)"
  has_headless=true
fi

for taskfile in "Makefile" "Taskfile.yml" "justfile"; do
  if [ -f "$SCAN_DIR/$taskfile" ]; then
    if grep -qi "claude\|agent\|ai-" "$SCAN_DIR/$taskfile" 2>/dev/null; then
      found "$taskfile has agent-related targets"
      has_headless=true
    fi
  fi
done

if [ "$has_ci_ai" = "true" ]; then
  pipeline_score=100
elif [ "$has_headless" = "true" ]; then
  pipeline_score=70
elif [ -d "$SCAN_DIR/.github" ] || [ -f "$SCAN_DIR/.gitlab-ci.yml" ]; then
  pipeline_score=20
else
  pipeline_score=0
fi

set_score 5 $pipeline_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$pipeline_score"

# ═════════════════════════════════════════════════════════════
# CATEGORY 7: MULTI-AGENT / MULTI-MODEL (weight 1.0x)
# ═════════════════════════════════════════════════════════════
# L7 (Multi-Agent Operator): Multiple agents run in parallel,
# coordinated by an orchestrator. Different models handle
# different jobs: Opus for architecture, Sonnet for code,
# Haiku for simple tasks. Cost-aware routing: expensive models
# for planning, cheap models for execution.
# ═════════════════════════════════════════════════════════════
header "7. Multi-Agent / Multi-Model (L7: Multi-Agent Operator)"
printf "  ${DIM}Do you use different models for different jobs?${RESET}\n"
printf "  ${DIM}At L7, expensive models handle architecture and planning,${RESET}\n"
printf "  ${DIM}fast models handle code generation, and cheap models handle${RESET}\n"
printf "  ${DIM}formatting and boilerplate. Cost-aware routing is the key.${RESET}\n\n"

multimodel_score=0
tools_found=0
has_model_routing=false
DETECTED_TOOLS=""

# Claude Code
if command -v claude &>/dev/null || [ -f "$HOME_DIR/.claude.json" ]; then
  found "Claude Code"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Claude Code,"
fi

# Cursor
if [ -f "$SCAN_DIR/.cursorrules" ] || [ -d "$HOME_DIR/.cursor" ] \
   || [ -d "$HOME_DIR/Library/Application Support/Cursor" ] \
   || [ -f "$SCAN_DIR/.cursorignore" ]; then
  found "Cursor"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Cursor,"
fi

# GitHub Copilot
if [ -f "$SCAN_DIR/.github/copilot-instructions.md" ] \
   || command -v github-copilot-cli &>/dev/null \
   || [ -f "$HOME_DIR/.config/github-copilot/hosts.json" ]; then
  found "GitHub Copilot"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}GitHub Copilot,"
fi

# Windsurf (Codeium)
if command -v windsurf &>/dev/null \
   || [ -f "$SCAN_DIR/.windsurfrules" ] \
   || [ -d "$HOME_DIR/Library/Application Support/Windsurf" ] \
   || [ -d "$HOME_DIR/.windsurf" ]; then
  found "Windsurf"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Windsurf,"
fi

# Aider
if command -v aider &>/dev/null || [ -f "$SCAN_DIR/.aider.conf.yml" ]; then
  found "Aider"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Aider,"
fi

# OpenAI Codex CLI
if command -v codex &>/dev/null; then
  found "OpenAI Codex CLI"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}OpenAI Codex CLI,"
fi

# Cline (VS Code extension)
if [ -d "$HOME_DIR/.cline" ] \
   || find "$HOME_DIR/.vscode/extensions" -maxdepth 1 -name "saoudrizwan.claude-dev*" 2>/dev/null | grep -q .; then
  found "Cline"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Cline,"
fi

# Continue.dev
if [ -f "$HOME_DIR/.continue/config.json" ] \
   || find "$HOME_DIR/.vscode/extensions" -maxdepth 1 -name "continue*" 2>/dev/null | grep -q .; then
  found "Continue.dev"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Continue.dev,"
fi

# Amazon Q Developer (formerly CodeWhisperer)
if command -v q &>/dev/null \
   || find "$HOME_DIR/.vscode/extensions" -maxdepth 1 -name "amazonwebservices.amazon-q*" 2>/dev/null | grep -q .; then
  found "Amazon Q Developer"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Amazon Q Developer,"
fi

# Tabnine
if find "$HOME_DIR/.vscode/extensions" -maxdepth 1 -name "tabnine*" 2>/dev/null | grep -q .; then
  found "Tabnine"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Tabnine,"
fi

# Supermaven
if find "$HOME_DIR/.vscode/extensions" -maxdepth 1 -name "supermaven*" 2>/dev/null | grep -q .; then
  found "Supermaven"
  tools_found=$((tools_found + 1))
  DETECTED_TOOLS="${DETECTED_TOOLS}Supermaven,"
fi

# Strip trailing comma
DETECTED_TOOLS=$(echo "$DETECTED_TOOLS" | sed 's/,$//')

if [ $tools_found -eq 0 ]; then
  not_found "No AI coding tools detected"
fi

if [ -d "$SCAN_DIR/.claude/skills" ]; then
  model_refs=$(grep -rl "model:\|sonnet\|opus\|haiku\|gpt-4\|gemini\|deepseek" \
    "$SCAN_DIR/.claude/skills" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$model_refs" -gt 0 ]; then
    found "Skills reference specific models ($model_refs files)"
    has_model_routing=true
  fi
fi

if find "$SCAN_DIR" -maxdepth 3 -name "skill-registry*" 2>/dev/null | grep -q .; then
  found "Skill registry found (agent routing infrastructure)"
  has_model_routing=true
fi

if [ "$has_model_routing" = "true" ]; then
  multimodel_score=100
elif [ $tools_found -ge 2 ]; then
  multimodel_score=50
elif [ $tools_found -eq 1 ]; then
  multimodel_score=20
else
  multimodel_score=0
fi

set_score 6 $multimodel_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$multimodel_score"

# ═════════════════════════════════════════════════════════════
# CATEGORY 8: BACKGROUND / ALWAYS-ON (weight 0.5x)
# ═════════════════════════════════════════════════════════════
# L8 (Always On): Agents run without you. Cron jobs, background
# processes, and cloud VMs keep agents working around the clock.
# You wake up to completed tasks, PRs ready for review, and
# reports waiting in your inbox. Asynchronous notification when
# work completes.
# ═════════════════════════════════════════════════════════════
header "8. Background / Always-On (L8: Always On)"
printf "  ${DIM}Do agents run without you? At L8, cron jobs, background${RESET}\n"
printf "  ${DIM}processes, and cloud VMs keep agents working around the${RESET}\n"
printf "  ${DIM}clock. You wake up to completed tasks, PRs ready for${RESET}\n"
printf "  ${DIM}review, and reports waiting in your inbox.${RESET}\n\n"

background_score=0
has_cron=false
has_daemon=false

cron_match=$(crontab -l 2>/dev/null | grep -ci "claude\|agent\|ai-\|agentic\|copilot\|cursor" || true)
if [ "$cron_match" -gt 0 ] 2>/dev/null; then
  found "Crontab has AI agent entries"
  has_cron=true
else
  not_found "No AI-related cron jobs"
fi

if [ -d "$HOME_DIR/Library/LaunchAgents" ]; then
  ai_agents=$(grep -rla "claude\|agentic" "$HOME_DIR/Library/LaunchAgents" 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  if [ "$ai_agents" -gt 0 ] 2>/dev/null; then
    found "LaunchAgents with AI references ($ai_agents)"
    has_daemon=true
  else
    not_found "No AI-related LaunchAgents"
  fi
fi

for sdir in "/etc/systemd/system" "$HOME_DIR/.config/systemd/user"; do
  if [ -d "$sdir" ]; then
    ai_services=$(grep -rl "claude\|agentic" "$sdir" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$ai_services" -gt 0 ]; then
      found "systemd services with AI references ($ai_services)"
      has_daemon=true
    fi
  fi
done

bg_scripts=$(find "$SCAN_DIR" -maxdepth 3 -type f \
  \( -name "*daemon*" -o -name "*background*" -o -name "*always-on*" -o -name "*cron*" \) \
  2>/dev/null | grep -v node_modules | grep -v .git | wc -l | tr -d ' ')
if [ "$bg_scripts" -gt 0 ]; then
  found "Background/daemon scripts in project ($bg_scripts files)"
fi

if [ "$has_daemon" = "true" ]; then
  background_score=100
elif [ "$has_cron" = "true" ]; then
  background_score=70
elif [ "$bg_scripts" -gt 0 ]; then
  background_score=30
else
  background_score=0
fi

set_score 7 $background_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$background_score"

# ═════════════════════════════════════════════════════════════
# CATEGORY 9: ORCHESTRATION / SWARM (weight 0.5x)
# ═════════════════════════════════════════════════════════════
# L9 (Swarm Architect): Agents manage other agents. The system
# creates, assigns, monitors, and retires agents dynamically.
# Agent-to-agent communication replaces human orchestration.
# Self-healing: failed agents are replaced automatically.
# Your role shifts from operator to architect.
# ═════════════════════════════════════════════════════════════
header "9. Orchestration / Swarm (L9: Swarm Architect)"
printf "  ${DIM}Do agents manage other agents? At L9, the system creates,${RESET}\n"
printf "  ${DIM}assigns, monitors, and retires agents dynamically. Agent-to-${RESET}\n"
printf "  ${DIM}agent communication replaces human orchestration. Self-healing${RESET}\n"
printf "  ${DIM}workflows recover from failures automatically.${RESET}\n\n"

orchestration_score=0
has_orchestrator=false
has_registry=false
has_coordination=false

registry_files=$(find "$SCAN_DIR" -maxdepth 3 -name "skill-registry*" 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ')
if [ "$registry_files" -gt 0 ]; then
  found "Skill registry found"
  has_registry=true
  reg_file=$(find "$SCAN_DIR" -maxdepth 3 -name "skill-registry*" 2>/dev/null | head -1)
  if [ -n "$reg_file" ] && command -v python3 &>/dev/null; then
    total=$(python3 -c "
import json
try:
    d = json.load(open('$reg_file'))
    print(d.get('total_skills', len(d.get('skills', {}))))
except: print('?')
" 2>/dev/null || echo "?")
    detail "$total skills registered"
  fi
fi

orch_files=$(find "$SCAN_DIR" -maxdepth 4 -type f \
  \( -name "*orchestrat*" -o -name "*dispatcher*" -o -name "*router*" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  2>/dev/null | wc -l | tr -d ' ')
if [ "$orch_files" -gt 0 ]; then
  found "Orchestrator/router files ($orch_files)"
  has_orchestrator=true
fi

if [ -f "$SCAN_DIR/.claude/skills/orchestrator/SKILL.md" ]; then
  found "Orchestrator SKILL.md"
  has_orchestrator=true
fi

comm_files=$(find "$SCAN_DIR" -maxdepth 4 -type f \
  \( -name "*communication*" -o -name "*notification*" -o -name "*handoff*" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  2>/dev/null | wc -l | tr -d ' ')
if [ "$comm_files" -gt 0 ]; then
  found "Agent communication/handoff patterns ($comm_files files)"
  has_coordination=true
fi

state_files=$(find "$SCAN_DIR" -maxdepth 4 -name "project-state*" \
  -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$state_files" -gt 0 ]; then
  found "Project state tracking ($state_files files)"
fi

if [ "$has_orchestrator" = "true" ] && [ "$has_registry" = "true" ] && [ "$has_coordination" = "true" ]; then
  orchestration_score=100
elif [ "$has_orchestrator" = "true" ] && [ "$has_registry" = "true" ]; then
  orchestration_score=80
elif [ "$has_orchestrator" = "true" ] || [ "$has_registry" = "true" ]; then
  orchestration_score=50
elif [ "$state_files" -gt 0 ]; then
  orchestration_score=20
else
  orchestration_score=0
fi

set_score 8 $orchestration_score
printf "\n  ${BOLD}Score: %d/100${RESET}\n" "$orchestration_score"

# ═════════════════════════════════════════════════════════════
# SCORE CALCULATION
# ═════════════════════════════════════════════════════════════
printf "\n\n"
hr
printf "${PINK}${BOLD}   CALCULATING YOUR SCORE${RESET}\n"
hr

total_weighted=0
max_weighted=0

for idx in 0 1 2 3 4 5 6 7 8; do
  score=$(get_score $idx)
  weight=$(get_weight $idx)
  weighted=$(python3 -c "print($score * $weight)" 2>/dev/null || echo "0")
  max_w=$(python3 -c "print(100 * $weight)" 2>/dev/null || echo "0")
  total_weighted=$(python3 -c "print($total_weighted + $weighted)" 2>/dev/null || echo "0")
  max_weighted=$(python3 -c "print($max_weighted + $max_w)" 2>/dev/null || echo "0")
done

final_score=$(python3 -c "print(round(($total_weighted / $max_weighted) * 900))" 2>/dev/null || echo "0")

# Determine level
LEVEL_NAMES="Terminal_Tourist Grounded Connected Skilled Compounding_Architect Harness_Builder Pipeline_Engineer Multi-Agent_Operator Always_On Swarm_Architect"
LEVEL_DISPLAY="Terminal Tourist|Grounded|Connected|Skilled|Compounding Architect|Harness Builder|Pipeline Engineer|Multi-Agent Operator|Always On|Swarm Architect"
LEVEL_THRESHOLDS="0 100 200 300 400 500 600 700 800 850"
LEVEL_DESCS="No rules, no memory, copy-paste from chat|Context files tell the AI your stack and standards|MCP servers pull live data into the agent|3+ custom skills for repeatable workflows|Plan-Delegate-Assess-Codify loop compounds knowledge|Automated guardrails force agent self-correction|Scripts and CI call the agent, not humans|Multiple models routed by cost and capability|Cron jobs and daemons run agents around the clock|Agents manage other agents autonomously"
LEVEL_MISSING="Create a rules file (CLAUDE.md, .cursorrules)|Connect MCP servers to live data sources|Build 3+ custom skills for common workflows|Set up memory and knowledge persistence|Add hooks, linters, and test guardrails|Run agents headlessly in scripts or CI|Route different models to different tasks|Set up cron/LaunchAgents for always-on agents|Build agent-to-agent coordination and self-healing|You are at the frontier"

if [ "$final_score" -lt 100 ]; then level=0
elif [ "$final_score" -lt 200 ]; then level=1
elif [ "$final_score" -lt 300 ]; then level=2
elif [ "$final_score" -lt 400 ]; then level=3
elif [ "$final_score" -lt 500 ]; then level=4
elif [ "$final_score" -lt 600 ]; then level=5
elif [ "$final_score" -lt 700 ]; then level=6
elif [ "$final_score" -lt 800 ]; then level=7
elif [ "$final_score" -lt 850 ]; then level=8
else level=9
fi

level_name=$(echo "$LEVEL_DISPLAY" | cut -d'|' -f$((level + 1)))

get_level_display() { echo "$LEVEL_DISPLAY" | cut -d'|' -f$(($1 + 1)); }
get_level_desc() { echo "$LEVEL_DESCS" | cut -d'|' -f$(($1 + 1)); }
get_level_missing() { echo "$LEVEL_MISSING" | cut -d'|' -f$(($1 + 1)); }

# ── Results ─────────────────────────────────────────────────
printf "\n"
printf "${BOLD}  YOUR SCORE${RESET}\n\n"
printf "     ${PINK}${BOLD}%d${RESET} / 900\n\n" "$final_score"
printf "     ${BOLD}Level %d: %s${RESET}\n" "$level" "$level_name"
printf "\n"

# ── Category Breakdown (Table) ──────────────────────────────
printf "  ${BOLD}Category Breakdown${RESET}\n\n"

printf "  ${DIM}┌──────────────────────────────┬────────┬────────┬──────────────────────┐${RESET}\n"
printf "  ${DIM}│${RESET} ${BOLD}%-28s${RESET} ${DIM}│${RESET} ${BOLD}Weight${RESET} ${DIM}│${RESET} ${BOLD}Score${RESET}  ${DIM}│${RESET} ${BOLD}Progress${RESET}             ${DIM}│${RESET}\n" "Category"
printf "  ${DIM}├──────────────────────────────┼────────┼────────┼──────────────────────┤${RESET}\n"

for idx in 0 1 2 3 4 5 6 7 8; do
  score=$(get_score $idx)
  name=$(get_display_name $idx)
  weight=$(get_weight $idx)
  printf "  ${DIM}│${RESET} %-28s ${DIM}│${RESET}  %sx   ${DIM}│${RESET}" "$name" "$weight"
  local_color="$RED"
  if [ "$score" -ge 70 ]; then local_color="$GREEN"
  elif [ "$score" -ge 40 ]; then local_color="$YELLOW"
  fi
  printf " ${local_color}%3d${RESET}/100${DIM}│${RESET} " "$score"
  bar "$score"
  printf " ${DIM}│${RESET}\n"
done

printf "  ${DIM}├──────────────────────────────┼────────┼────────┼──────────────────────┤${RESET}\n"
printf "  ${DIM}│${RESET} ${BOLD}%-28s${RESET} ${DIM}│${RESET}        ${DIM}│${RESET} ${PINK}${BOLD}%3d${RESET}/900${DIM}│${RESET}                      ${DIM}│${RESET}\n" "TOTAL" "$final_score"
printf "  ${DIM}└──────────────────────────────┴────────┴────────┴──────────────────────┘${RESET}\n"

# ── Level Progression ─────────────────────────────────────────
printf "\n"
hr
printf "\n  ${BOLD}Level Progression${RESET}\n"
printf "  ${DIM}Based on: oaseru.dev/blog/10-levels-of-agentic-engineering${RESET}\n\n"

BLUE='\033[0;34m'
WHITE='\033[1;37m'

for lvl in 0 1 2 3 4 5 6 7 8 9; do
  lvl_name=$(get_level_display $lvl)
  lvl_desc=$(get_level_desc $lvl)
  lvl_missing=$(get_level_missing $lvl)

  if [ $lvl -lt $level ]; then
    # Completed level
    printf "  ${GREEN}${BOLD}✓ L%d  %-24s${RESET} ${DIM}%s${RESET}\n" "$lvl" "$lvl_name" "$lvl_desc"
  elif [ $lvl -eq $level ]; then
    # Current level — highlighted
    printf "\n  ${PINK}${BOLD}▸ L%d  %-24s${RESET} ${WHITE}← YOU ARE HERE${RESET}\n" "$lvl" "$lvl_name"
    printf "  ${PINK}${BOLD}  │${RESET}   ${CYAN}%s${RESET}\n" "$lvl_desc"
    # Show category scores for current level
    current_cat_score=$(get_score $lvl)
    if [ "$current_cat_score" -lt 100 ] && [ $lvl -le 8 ]; then
      printf "  ${PINK}${BOLD}  │${RESET}   ${YELLOW}Missing: %s${RESET}\n" "$lvl_missing"
    fi
    printf "\n"
  else
    # Future level
    if [ $lvl -eq $((level + 1)) ]; then
      # Next level — show what's needed
      printf "  ${DIM}○ L%d  %-24s${RESET} ${DIM}%s${RESET}\n" "$lvl" "$lvl_name" "$lvl_desc"
      printf "  ${DIM}  │${RESET}   ${YELLOW}To unlock: %s${RESET}\n" "$lvl_missing"
    else
      # Locked levels
      printf "  ${DIM}○ L%d  %-24s %s${RESET}\n" "$lvl" "$lvl_name" "$lvl_desc"
    fi
  fi
done

printf "\n"

# ── JSON Output for AI Analysis ────────────────────────────
# Structured data that the current AI model can consume
# to generate personalized, tool-specific recommendations
# based on https://oaseru.dev/blog/10-levels-of-agentic-engineering

# Build signals JSON (what was detected)
signals_json=""
[ $context_files_found -gt 0 ] && signals_json="${signals_json}\"context_files_found\":$context_files_found,"
[ $mcp_server_count -gt 0 ] && signals_json="${signals_json}\"mcp_servers\":$mcp_server_count,"
[ $skill_count -gt 0 ] && signals_json="${signals_json}\"skill_count\":$skill_count,"
[ $memory_files -gt 0 ] && signals_json="${signals_json}\"memory_files\":$memory_files,"
[ "$has_memory_index" = "true" ] && signals_json="${signals_json}\"has_memory_index\":true,"
[ "$has_knowledge" = "true" ] && signals_json="${signals_json}\"has_knowledge\":true,"
[ "$has_ai_hooks" = "true" ] && signals_json="${signals_json}\"has_ai_hooks\":true,"
[ "$has_git_hooks" = "true" ] && signals_json="${signals_json}\"has_git_hooks\":true,"
[ "$has_quality_tools" = "true" ] && signals_json="${signals_json}\"has_quality_tools\":true,"
[ "$has_ci_ai" = "true" ] && signals_json="${signals_json}\"has_ci_ai\":true,"
[ "$has_headless" = "true" ] && signals_json="${signals_json}\"has_headless\":true,"
[ "$has_model_routing" = "true" ] && signals_json="${signals_json}\"has_model_routing\":true,"
[ "$has_cron" = "true" ] && signals_json="${signals_json}\"has_cron\":true,"
[ "$has_daemon" = "true" ] && signals_json="${signals_json}\"has_daemon\":true,"
[ "$has_orchestrator" = "true" ] && signals_json="${signals_json}\"has_orchestrator\":true,"
[ "$has_registry" = "true" ] && signals_json="${signals_json}\"has_registry\":true,"
[ "$has_coordination" = "true" ] && signals_json="${signals_json}\"has_coordination\":true,"
signals_json=$(echo "${signals_json}" | sed 's/,$//')

# Build gaps array (categories scoring below 100)
gaps_json=""
for idx in 0 1 2 3 4 5 6 7 8; do
  score=$(get_score $idx)
  if [ "$score" -lt 100 ]; then
    name=$(get_display_name $idx)
    gaps_json="${gaps_json}{\"category\":\"$name\",\"score\":$score},"
  fi
done
gaps_json=$(echo "${gaps_json}" | sed 's/,$//')

# Build categories JSON
cat_json=""
for idx in 0 1 2 3 4 5 6 7 8; do
  score=$(get_score $idx)
  name=$(get_display_name $idx)
  weight=$(get_weight $idx)
  cat_json="${cat_json}{\"name\":\"$name\",\"score\":$score,\"weight\":$weight},"
done
cat_json=$(echo "${cat_json}" | sed 's/,$//')

printf "\n"
hr
printf "\n  ${DIM}Structured scan data for AI-driven analysis:${RESET}\n\n"

cat << ENDJSON
<!--AUDIT_JSON
{
  "version": "$VERSION",
  "scan_dir": "$SCAN_DIR",
  "final_score": $final_score,
  "max_score": 900,
  "level": $level,
  "level_name": "$level_name",
  "detected_tools": "$(echo "$DETECTED_TOOLS" | sed 's/"/\\"/g')",
  "categories": [$cat_json],
  "signals": {$signals_json},
  "gaps": [$gaps_json],
  "reference": "https://oaseru.dev/blog/10-levels-of-agentic-engineering"
}
AUDIT_JSON-->
ENDJSON

# ── Submit to Leaderboard ──────────────────────────────────
printf "\n"
hr
printf "\n  ${BOLD}Submit to Global Leaderboard${RESET}\n\n"
printf "  ${DIM}Share your score on the oaseru.dev leaderboard.${RESET}\n\n"

submit_choice=""
if [ -t 0 ]; then
  read -rp "  Submit your score? (y/n): " submit_choice
else
  printf "  ${DIM}(Non-interactive mode, skipping submission)${RESET}\n"
fi

if [ "$submit_choice" = "y" ] || [ "$submit_choice" = "Y" ]; then
  read -rp "  Enter your name/handle: " username

  if [ -z "$username" ]; then
    printf "  ${RED}No name provided. Skipping submission.${RESET}\n"
  else
    payload=$(python3 -c "
import json
print(json.dumps({
    'username': '''$username''',
    'score': $final_score,
    'level': $level,
    'levelName': '$level_name',
    'categories': {$(for idx in 0 1 2 3 4 5 6 7 8; do echo -n \"\\\"$(get_display_name $idx)\\\":$(get_score $idx),\"; done | sed 's/,$//')}
}))
" 2>/dev/null)

    response=$(curl -s -w "\n%{http_code}" -X POST "$SUBMIT_URL" \
      -H "Content-Type: application/json" \
      -d "$payload" 2>/dev/null || echo -e "\n000")

    http_code=$(echo "$response" | tail -1)

    if [ "$http_code" = "200" ]; then
      printf "\n  ${GREEN}${BOLD}Score submitted!${RESET}\n"
      printf "  ${DIM}View the leaderboard: https://oaseru.dev/audit/leaderboard${RESET}\n"
    else
      printf "\n  ${YELLOW}Submission failed (HTTP $http_code). You can submit manually at:${RESET}\n"
      printf "  ${DIM}https://oaseru.dev/audit${RESET}\n"
    fi
  fi
fi

# ── Footer ──────────────────────────────────────────────────
printf "\n"
hr
printf "\n  ${DIM}Learn more about each level:${RESET}\n"
printf "  ${CYAN}https://oaseru.dev/blog/10-levels-of-agentic-engineering${RESET}\n\n"
printf "  ${DIM}Full blog series on agentic engineering:${RESET}\n"
printf "  ${CYAN}https://oaseru.dev/blog${RESET}\n\n"
hr
printf "  ${DIM}Agentic Skill Auditor v%s by oaseru.dev${RESET}\n\n" "$VERSION"
