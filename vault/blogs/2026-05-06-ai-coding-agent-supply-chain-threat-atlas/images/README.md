# Infographic Assets — Supply Chain Threat Atlas

Generated for: [The AI Coding Agent Supply Chain Threat Atlas](../draft.md)

## Files

| File | Type | Dimensions | Alt text |
|------|------|-----------|----------|
| `timeline-ribbon.svg` | Gantt timeline | 1384 × 604 | Horizontal Gantt timeline of AI coding agent supply chain attacks from November 2024 to May 2026, grouped by vector type: MCP (purple/red), npm/PyPI (orange), IDE/CLI (green), and Tool-Poisoning (red). Critical-severity incidents are highlighted in red. |
| `timeline-ribbon.mmd` | Mermaid source | — | Source for timeline-ribbon.svg |
| `sankey-attack-chain.svg` | Sankey flow | 600 × 400 | Sankey flow diagram showing attack paths from source (npm/PyPI, MCP Registry, IDE Extension) through distribution channel and trigger to payload type (RAT Deploy, Credential Harvest, Repository Exfil, Token Theft). Flow width proportional to confirmed incident count. |
| `sankey-attack-chain.mmd` | Mermaid source | — | Source for sankey-attack-chain.svg |
| `defense-heatmap.svg` | Grid heatmap | 900 × 460 | Grid heatmap showing mitigation coverage for 8 AI coding agents (Claude Code, Cursor, Codex CLI, Gemini CLI, Goose, Aider, Copilot Workspace, Devin) across 6 mitigations (Sandbox/Firecracker, Deny-list CLI, Least-priv tokens, MCP server allowlist, Registry age-gate, Prompt-injection guard). Green = implemented, yellow = partial, red = missing/unknown. |
| `defense-heatmap.mmd` | Mermaid source | — | Mermaid data source + quadrant fallback for defense-heatmap.svg |

## Usage in blog post

```markdown
![Timeline of supply chain attacks Nov 2024–May 2026](images/timeline-ribbon.svg)

![Attack-chain Sankey: source → distribution → trigger → payload](images/sankey-attack-chain.svg)

![Agent defense coverage matrix](images/defense-heatmap.svg)
```

## Generation notes

- `timeline-ribbon.svg` and `sankey-attack-chain.svg` rendered via `mmdc` ([@mermaid-js/mermaid-cli](https://github.com/mermaid-js/mermaid-cli)) with system Chromium + `--no-sandbox`
- `defense-heatmap.svg` hand-crafted SVG grid (Mermaid v11 quadrant chart has a color-rendering NaN bug for unlabelled data points; raw SVG used instead for the primary deliverable)
- Renderer: `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium npx @mermaid-js/mermaid-cli`
