# Agentic Skill Auditor

An AI agent skill that scans your machine and project for agentic engineering maturity. It scores you 0-900 across 9 categories and tells you exactly where you stand on the 10-level agentic engineering spectrum.

## How to Use

This is a skill designed to run from inside your AI coding agent. Clone the repo, then ask your agent to run the scan.

```bash
git clone https://github.com/Oaseru17/agentic-skill-auditor.git
```

Then from your agent (Claude Code, Cursor, Copilot, Windsurf, etc.):

> "Run the agentic skill auditor on my project"

or

> "Scan my agentic engineering setup using ./agentic-skill-auditor/scan.sh"

The agent executes `scan.sh`, reads the structured output (including machine-readable JSON), and gives you personalized recommendations based on your results, your stack, and the tools you already have installed.

### How It Works

1. Your agent runs `./scan.sh /path/to/your/project`
2. The script scans your machine for AI tool configurations, skills, memory, hooks, pipelines, and orchestration patterns
3. It outputs a visual report for you and structured JSON for the agent
4. The agent reads the JSON, understands your gaps, and gives you specific, actionable next steps tailored to your setup

The shell script is the scanner. Your AI agent is the interface.

## What It Scans

The audit checks 9 categories, each mapped to a level of agentic engineering maturity:

| Category | Weight | What It Checks |
|----------|--------|----------------|
| Context Setup | 1.5x | CLAUDE.md, .cursorrules, copilot-instructions.md, .windsurfrules |
| Tool Connections (MCP) | 1.0x | MCP server configs across all tools |
| Skills & Commands | 1.0x | SKILL.md files, custom commands, slash commands |
| Memory & Compounding | 1.0x | Memory directories, MEMORY.md, knowledge files |
| Feedback Loops & Hooks | 1.5x | AI lifecycle hooks, git hooks, quality tools |
| Pipeline / Headless | 1.0x | CI/CD with AI agents, headless scripts |
| Multi-Agent / Multi-Model | 1.0x | Multiple AI tools, model routing, skill registries |
| Background / Always-On | 0.5x | Cron jobs, LaunchAgents, systemd services |
| Orchestration / Swarm | 0.5x | Orchestrator configs, agent coordination, task routing |

### AI Tools Detected

The auditor scans for 11 AI coding tools: Claude Code, Cursor, GitHub Copilot, Windsurf, Aider, OpenAI Codex CLI, Cline, Continue.dev, Amazon Q Developer, Tabnine, and Supermaven.

## The 10 Levels

| Level | Name | Score Range | You Are Here When... |
|-------|------|-------------|----------------------|
| 0 | Terminal Tourist | 0-99 | No config, no context, copy-paste from chat |
| 1 | Grounded | 100-199 | A rules/context file exists for your project |
| 2 | Connected | 200-299 | MCP servers pull live data into the agent |
| 3 | Skilled | 300-399 | 3+ custom skills for repeatable workflows |
| 4 | Compounding Architect | 400-499 | Memory and knowledge persist across sessions |
| 5 | Harness Builder | 500-599 | Hooks and tests create automated guardrails |
| 6 | Pipeline Engineer | 600-699 | Scripts and CI call the agent, not humans |
| 7 | Multi-Agent Operator | 700-799 | Multiple models routed by cost and capability |
| 8 | Always On | 800-849 | Agents run on schedules without you |
| 9 | Swarm Architect | 850-900 | Agents manage other agents autonomously |

## Requirements

- Bash 3.2+ (ships with macOS and most Linux distributions)
- Python 3 (for JSON parsing and score calculation)
- curl (for optional leaderboard submission)

## Submit Your Score

After scanning, you can submit your score to the global leaderboard at [oaseru.dev/audit/leaderboard](https://oaseru.dev/audit/leaderboard).

## Web Version

Take the quiz online at [oaseru.dev/audit](https://oaseru.dev/audit).

## Contributing

This auditor is designed to grow with the industry. As new AI tools, patterns, and workflows emerge, the scan categories and detection logic should evolve too.

Ways to contribute:

- **Add detection for new AI tools** as they launch
- **Improve scoring heuristics** for existing categories
- **Add new scan categories** as the field evolves
- **Report false positives/negatives** in detection
- **Improve cross-platform support** (Windows/WSL, Linux distros)

## Learn More

- [The 10 Levels of Agentic Engineering](https://oaseru.dev/blog/10-levels-of-agentic-engineering)
- [Full blog series on agentic engineering](https://oaseru.dev/blog)

## License

MIT
