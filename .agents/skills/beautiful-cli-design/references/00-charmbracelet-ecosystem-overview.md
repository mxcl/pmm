# Charmbracelet Ecosystem -- Complete Map for TypeScript/Node.js Developers

## The Ecosystem at a Glance

Charmbracelet is a company building beautiful terminal tools in Go. Their
ecosystem is cohesive: each tool builds on the others. For TypeScript/Node.js
developers, some tools have direct JS ports, others have JS equivalents, and
some are best used as CLI tools called from Node.js.

```
                    CHARMBRACELET ECOSYSTEM
                    =======================

    Go-Native Libraries          CLI Tools (Any Language)
    ┌──────────────────┐         ┌──────────────────────┐
    │ Bubble Tea (TUI) │         │ Gum (prompts)        │
    │ Lip Gloss (style)│         │ VHS (GIF recording)  │
    │ Bubbles (widgets)│         │ Glow (md viewer)     │
    │ Glamour (md)     │         │ Mods (AI pipelines)  │
    │ Huh? (forms)     │         │ Freeze (screenshots) │
    │ Log (logging)    │         │ Soft Serve (git)     │
    │ Wish (SSH)       │         │ Pop (email)          │
    │ Harmonica (anim) │         │ Skate (kv store)     │
    └──────────────────┘         └──────────────────────┘
            │                              │
            ▼                              ▼
    JS Ports/Equivalents         Call from Node.js via
    ┌──────────────────┐         ┌──────────────────────┐
    │ @charmland/       │         │ execSync('gum ...')  │
    │   lipgloss (beta)│         │ execSync('vhs ...')  │
    │ Ink (React TUI)  │         │ execSync('glow ...')  │
    │ @inkjs/ui        │         │ execSync('mods ...')  │
    │ @clack/prompts   │         │                      │
    │ marked-terminal  │         │                      │
    │ consola          │         │                      │
    └──────────────────┘         └──────────────────────┘
```

## Tool-by-Tool Mapping

| Charm Tool | Purpose | JS Port | JS Equivalent | Call via CLI |
|-----------|---------|---------|---------------|-------------|
| **Lip Gloss** | Terminal styling | `@charmland/lipgloss` (beta) | chalk + cli-boxes | - |
| **Bubble Tea** | Full TUI framework | - | `ink` (React) | - |
| **Bubbles** | TUI components | - | `@inkjs/ui` | - |
| **Glamour** | Markdown rendering | - | `marked-terminal` | `glow` |
| **Huh?** | Terminal forms | - | `@clack/prompts` | `gum` |
| **Log** | Structured logging | - | `consola` / `pino` | `gum log` |
| **VHS** | GIF recording | - | - | `vhs` |
| **Gum** | Shell prompts | - | - | `gum` |
| **Harmonica** | Spring animation | - | `react-spring` | - |

## Decision Matrix: When to Use What

### "I need styled terminal output"

```
Want native Go?  --> Lip Gloss
Want JS native?  --> @charmland/lipgloss (beta, limited)
                     OR chalk + cli-boxes (stable, mature)
Want zero deps?  --> gum style (shell out)
```

### "I need an interactive TUI"

```
Team knows React?     --> Ink + @inkjs/ui
Team knows Go?        --> Bubble Tea + Bubbles
Need maximum perf?    --> Ratatui (Rust)
Python ecosystem?     --> Textual
```

### "I need user prompts"

```
From shell script?    --> Gum
From Node.js, modern? --> @clack/prompts
From Node.js, mature? --> @inquirer/prompts
From Go?              --> Huh?
Zero dependency?      --> Gum via execSync
```

### "I need to render markdown"

```
In Go?                --> Glamour
In Node.js?           --> marked + marked-terminal
Quick preview?        --> glow (CLI)
In an Ink app?        --> marked-terminal output in <Text>
```

### "I need terminal logging"

```
In Go?                --> charmbracelet/log
In Node.js?           --> consola (closest match)
                         OR pino (JSON-focused)
                         OR winston (enterprise)
From shell?           --> gum log
```

### "I need demo GIFs"

```
Automated/CI?         --> VHS
Quick recording?      --> vhs record
Screenshots only?     --> Freeze (charmbracelet/freeze)
From Node.js?         --> Generate .tape file, exec vhs
```

## Architecture Patterns

### Pattern 1: Ink + @charmland/lipgloss (Full JS Native)

Use when building a complete Node.js TUI application.

```tsx
import { render, Box, Text } from 'ink';
import { Style, Color, Table, RoundedBorder } from '@charmland/lipgloss';

// Use lipgloss for complex styled blocks
const styledTable = new Table()
  .headers("Name", "Status")
  .row("API", "Running")
  .borderStyle(RoundedBorder())
  .render();

// Embed in Ink layout
function App() {
  return (
    <Box flexDirection="column">
      <Box borderStyle="round" borderColor="blue" padding={1}>
        <Text bold>Dashboard</Text>
      </Box>
      <Text>{styledTable}</Text>
    </Box>
  );
}
```

### Pattern 2: Gum for Prompts + Ink for Display (Hybrid)

Use when you need gorgeous prompts but also real-time UI.

```typescript
import { execSync } from 'child_process';
import { render, Box, Text } from 'ink';

// Phase 1: Collect input via Gum (beautiful, zero effort)
const name = execSync('gum input --placeholder "Project name"', {
  encoding: 'utf-8', stdio: ['inherit', 'pipe', 'inherit']
}).trim();

const framework = execSync('gum choose React Vue Svelte', {
  encoding: 'utf-8', stdio: ['inherit', 'pipe', 'inherit']
}).trim();

// Phase 2: Show live progress via Ink (React powers)
function BuildProgress({ name, framework }) {
  const [step, setStep] = useState(0);
  // ... real-time build UI
}

render(<BuildProgress name={name} framework={framework} />);
```

### Pattern 3: Pure Gum (Zero-Dependency from Node.js)

Use when you want beautiful prompts without any npm dependencies.

```typescript
import { execSync } from 'child_process';

// Entire setup wizard using only gum
function setupWizard() {
  const type = exec('gum choose fix feat docs style refactor test chore');
  const scope = exec('gum input --placeholder "scope"');
  const msg = exec(`gum input --value "${type}(${scope}): " --placeholder "Summary"`);
  const body = exec('gum write --placeholder "Details (Ctrl+D to finish)"');

  if (confirm('Commit changes?')) {
    execSync(`git commit -m ${JSON.stringify(msg)} -m ${JSON.stringify(body)}`);
  }
}

function exec(cmd) {
  return execSync(cmd, { encoding: 'utf-8', stdio: ['inherit', 'pipe', 'inherit'] }).trim();
}

function confirm(msg) {
  try { execSync(`gum confirm ${JSON.stringify(msg)}`, { stdio: 'inherit' }); return true; }
  catch { return false; }
}
```

### Pattern 4: VHS for Automated Demo Generation

```typescript
import { writeFileSync } from 'fs';
import { execSync } from 'child_process';

function generateDemo(commands: string[], output: string) {
  const tape = [
    `Output ${output}`,
    'Set Shell "zsh"',
    'Set FontSize 18',
    'Set Width 1200',
    'Set Height 600',
    'Set Theme "Catppuccin Frappe"',
    'Set WindowBar Colorful',
    'Set TypingSpeed 50ms',
    '',
    'Hide',
    'Type "cd /tmp/demo && clear"',
    'Enter',
    'Sleep 500ms',
    'Show',
    '',
    ...commands.flatMap(cmd => [
      `Type ${JSON.stringify(cmd)}`,
      'Sleep 300ms',
      'Enter',
      'Sleep 2s',
    ]),
  ].join('\n');

  writeFileSync('/tmp/demo.tape', tape);
  execSync('vhs /tmp/demo.tape', { stdio: 'inherit' });
}
```

## NO_COLOR / Terminal Capability Handling

All Charmbracelet tools respect these standards:

| Signal | Effect |
|--------|--------|
| `NO_COLOR=1` | Strip all ANSI color codes |
| `TERM=dumb` | Minimal output, no fancy rendering |
| Non-TTY stdout | Auto-strip formatting when piped |
| `CLICOLOR=0` | Disable color (same as NO_COLOR) |
| `CLICOLOR_FORCE=1` | Force color even in pipes |
| `COLORTERM=truecolor` | Enable 24-bit color |
| `COLORTERM=256color` | Enable 256-color mode |

In the JS ecosystem:
- **chalk**: Auto-detects TTY, respects NO_COLOR, supports `--color` flag
- **Ink**: Adapts rendering for CI (CI=true env var)
- **@charmland/lipgloss**: Follows Go lipgloss conventions
- **Gum**: Full NO_COLOR support, `--no-color` flag

## Reference File Index

1. `01-charmland-lipgloss-js.md` -- JS port API, Style, Color, Table, List, Tree
2. `02-ink-react-for-cli.md` -- Ink components, hooks, layout, borders, full API
3. `03-inkjs-ui-components.md` -- Pre-built components, theming system
4. `04-bubbletea-elm-architecture.md` -- Model-Update-View pattern, mapping to React
5. `05-lipgloss-go-v2.md` -- Complete Go API (source of truth for JS port)
6. `06-glamour-markdown-rendering.md` -- Terminal markdown, JS equivalents
7. `07-vhs-tape-reference.md` -- Complete tape command reference, settings, themes
8. `08-gum-shell-prompts.md` -- All gum commands, Node.js wrapper patterns
9. `09-log-structured-logging.md` -- Charm log API, JS equivalents
10. `10-huh-terminal-forms.md` -- Form fields, dynamic forms, @clack comparison
