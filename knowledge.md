# Agentic Skill Auditor — Knowledge

## The 10 Levels of Agentic Engineering
Source: https://oaseru.dev/blog/10-levels-of-agentic-engineering

### L0 — Terminal Tourist (0-99)
- No rules file or context configuration. No memory between sessions. Manual copy-paste workflow.
- Each conversation begins from scratch. AI functions as a search engine substitute.
- **To advance:** Create a foundational context file documenting your project's standards and architecture.

### L1 — Grounded (100-199)
- Rules files (CLAUDE.md, .cursorrules, copilot-instructions.md) are documented.
- Stack, language, framework, and conventions are recorded. Project structure is described.
- The AI produces relevant code on the first try more often.
- **To advance:** A 20-minute investment in a context file saves hours every week. Single highest-leverage step.

### L2 — Connected (200-299)
- MCP servers configured and pulling real data. Agents query databases, read docs, access GitHub.
- Context is dynamic, not just static files. System understands actual operational state.
- **To advance:** Move beyond static documentation by enabling direct integrations with your infrastructure.

### L3 — Skilled (300-399)
- Three or more custom skills established (SKILL.md files or equivalent).
- Skills address PR review, deployment, testing, documentation. Agent can execute multi-step tasks from a single command.
- Workflows remain consistent and auditable.
- **To advance:** Develop and formalize specific skillsets the agent can reliably execute without re-explanation.

### L4 — Compounding Architect (400-499)
- Continuous improvement loop: **Plan → Delegate → Assess → Codify**.
- Every task feeds learnings back into the system. Memory files persist knowledge across sessions.
- Knowledge files capture domain-specific learnings inside each skill.
- This is where the compounding effect begins. Your system gets smarter with every interaction.
- **To advance:** Systematize feedback loops that transform task learnings into permanent system improvements.

### L5 — Harness Builder (500-599)
- Tests execute automatically after agent code generation. Linters and formatters enforce standards without human review.
- Pre-commit hooks prevent problematic code from reaching repositories.
- Agent iterates until guardrails pass, not until output "looks right."
- **Key insight:** Backpressure. You are not reviewing the agent's work manually — systems do it for you.
- **To advance:** Build automated feedback systems that guide agent behavior through objective constraints.

### L6 — Pipeline Engineer (600-699)
- Headless / non-interactive mode configured. Scripts and CI jobs invoke agents programmatically.
- Agent executes within deployment, testing, or review pipelines.
- Human involvement is supervisory, not operational.
- **To advance:** Integrate agents into your infrastructure as headless services triggered by scripts or CI systems.

### L7 — Multi-Agent Operator (700-799)
- Parallel agents handle independent tasks simultaneously. Orchestrator coordinates task distribution.
- Different models handle different jobs based on capabilities.
- Cost-aware routing: expensive models for planning, cheap models for execution.
- **To advance:** Design orchestration logic that distributes work across specialized agents based on task requirements and economic efficiency.

### L8 — Always On (800-849)
- Cron-triggered agent workflows. Background agents monitor and respond to events.
- Cloud VMs run persistent agent processes. Asynchronous notification when work completes.
- **To advance:** Establish persistent infrastructure that runs agents on schedules or event-driven triggers.

### L9 — Swarm Architect (850-900)
- Agents spawn and manage sub-agents dynamically. Task decomposition and assignment occur automatically.
- Agent-to-agent communication and coordination. Self-healing: failed agents are replaced automatically.
- Human role shifts from operator to architect.
- **To advance:** Design systems where agents independently create, manage, and retire other agents.

### Framework Principles
- Levels are cumulative; each builds on previous foundations
- Advancement requires honest self-assessment, not just tool installation
- Progress should be intentional, one level at a time
- The framework measures practice and output, not configuration alone

## Scoring Philosophy

### [AUTO-LEARNED] Multi-model scoring should reward routing, not tool count
- Model routing (Opus for planning, Sonnet for code, Haiku for docs) IS multi-model
- Having multiple AI tools installed (Cursor + Claude) doesn't make you more "multi-agent"
- The scoring logic was fixed: `has_model_routing = true` alone scores 100/100
- Previous bug: capped at 80 if only 1 AI tool detected, even with full model routing across 60+ skills

### [AUTO-LEARNED] AI-driven analysis replaces static recommendations
- The scan outputs structured JSON (`<!--AUDIT_JSON ... AUDIT_JSON-->`) at the end
- The current AI model in the session consumes this JSON to generate personalized analysis
- Blog reference is the framework for all analysis
- The detected tools list (`DETECTED_TOOLS`) tells the AI which tool-specific next steps to recommend
  - e.g., Claude Code user → recommend MCP servers, hooks, skills
  - e.g., Cursor user → recommend .cursorrules, Composer, multi-file edits
  - e.g., Copilot user → recommend copilot-instructions.md, Copilot Chat, workspace agents
- Static hardcoded level descriptions and next steps were removed in favor of AI-generated analysis

### [AUTO-LEARNED] Level progression UI shows all 10 levels with visual indicators
- Completed levels: green checkmark (✓)
- Current level: pink highlight (▸) with "← YOU ARE HERE" and what's missing
- Next level: shows "To unlock:" with specific action needed
- Locked levels: dimmed with description
- Level names match the blog: Terminal Tourist, Grounded, Connected, Skilled, Compounding Architect, Harness Builder, Pipeline Engineer, Multi-Agent Operator, Always On, Swarm Architect

### [AUTO-LEARNED] Script runs in both interactive and non-interactive modes
- Interactive (terminal): prompts for leaderboard submission
- Non-interactive (piped/agent): skips submission, outputs JSON for AI consumption
- JSON is wrapped in HTML comment tags so it doesn't clutter visual output but is parseable

## Category-to-Level Mapping
| Category (scan) | Maps to Level | Weight |
|---|---|---|
| Context Setup | L1 Grounded | 1.5x |
| Tool Connections (MCP) | L2 Connected | 1.0x |
| Skills & Commands | L3 Skilled | 1.0x |
| Memory & Compounding | L4 Compounding Architect | 1.0x |
| Feedback Loops & Hooks | L5 Harness Builder | 1.5x |
| Pipeline / Headless | L6 Pipeline Engineer | 1.0x |
| Multi-Agent / Multi-Model | L7 Multi-Agent Operator | 1.0x |
| Background / Always-On | L8 Always On | 0.5x |
| Orchestration / Swarm | L9 Swarm Architect | 0.5x |

## Detection Patterns
- MCP servers: checks `~/.claude.json`, `.claude/settings.json`, `.mcp.json`, `.cursor/mcp.json`, `.vscode/settings.json`
- Claude Code MCP: uses `claude mcp list` command when available
- Skills: counts `SKILL.md` files in `.claude/skills/` (project) and `~/.claude/skills/` (global)
- Hooks: looks for `"hooks"` key in `.claude/settings.json` or `~/.claude/settings.json`
- Background: checks crontab, LaunchAgents (macOS), systemd (Linux)
- Tools detected: Claude Code, Cursor, GitHub Copilot, Windsurf, Aider, Codex CLI, Cline, Continue.dev, Amazon Q, Tabnine, Supermaven

## Directory
- Renamed from `agentic-audit-skill` to `agentic-skill-auditor` (2026-03-19)
- Path: `/Users/oaseru/Documents/vaule-streams/micro-influx/agentic-skill-auditor/`
