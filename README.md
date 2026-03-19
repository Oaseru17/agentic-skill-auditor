# Agentic Engineering Audit

Scan your machine and project for AI engineering maturity. Get scored 0-900 across 9 categories. Find out where you stand on the agentic engineering spectrum.

## Quick Start

```bash
git clone https://github.com/oaseru/agentic-skill-auditor.git
cd agentic-skill-auditor
./scan.sh
```

To scan a specific project directory:

```bash
./scan.sh /path/to/your/project
```

## What It Scans

The audit checks 9 categories, each mapped to a level of agentic engineering maturity:

| Category | Weight | What It Checks |
|----------|--------|----------------|
| Context Setup | 1.5x | CLAUDE.md, .cursorrules, copilot-instructions.md |
| Tool Connections (MCP) | 1.0x | MCP server configs across tools |
| Skills & Commands | 1.0x | SKILL.md files, custom commands |
| Memory & Compounding | 1.0x | Memory directories, MEMORY.md, knowledge files |
| Feedback Loops & Hooks | 1.5x | AI hooks, git hooks, quality tools |
| Pipeline / Headless | 1.0x | CI/CD with AI, headless agent scripts |
| Multi-Agent / Multi-Model | 1.0x | Multiple AI tools, model routing in skills |
| Background / Always-On | 0.5x | Cron jobs, LaunchAgents, systemd services |
| Orchestration / Swarm | 0.5x | Skill registries, orchestrator configs, agent coordination |

## The 10 Levels

| Level | Name | Score Range |
|-------|------|-------------|
| 0 | Unaware | 0-99 |
| 1 | Curious | 100-199 |
| 2 | Connected | 200-299 |
| 3 | Structured | 300-399 |
| 4 | Compounding | 400-499 |
| 5 | Automated | 500-599 |
| 6 | Multi-Agent | 600-699 |
| 7 | Orchestrated | 700-799 |
| 8 | Autonomous | 800-849 |
| 9 | Frontier | 850-900 |

## Requirements

- Bash 3.2+ (ships with macOS and most Linux distributions)
- Python 3 (for JSON parsing and score calculation)
- curl (for optional leaderboard submission)

## Submit Your Score

After scanning, you can submit your score to the global leaderboard at [oaseru.dev/audit/leaderboard](https://oaseru.dev/audit/leaderboard).

## Web Version

Take the quiz online at [oaseru.dev/audit](https://oaseru.dev/audit).

## Contributing

This tool is designed to grow with the industry. As new AI tools, patterns, and workflows emerge, the scan categories and detection logic should evolve too.

Ways to contribute:

- **Add detection for new AI tools** (Windsurf, Cline, Devin, etc.)
- **Improve scoring heuristics** for existing categories
- **Add new scan categories** as the field evolves
- **Report false positives/negatives** in detection
- **Improve cross-platform support** (Windows/WSL, Linux distros)

## Learn More

- [The 10 Levels of Agentic Engineering](https://oaseru.dev/blog/10-levels-of-agentic-engineering)
- [Full blog series on agentic engineering](https://oaseru.dev/blog)

## License

MIT
