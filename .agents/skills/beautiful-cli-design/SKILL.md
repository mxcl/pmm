---
license: Apache-2.0
name: beautiful-cli-design
description: |
  Expert in making CLI tools visually stunning and delightful — not just functional. Covers ANSI color systems (16/256/truecolor with graceful degradation), Unicode box drawing, progress indicators, tables, animated output, ASCII art, rich text, interactive prompts, and full TUI frameworks (Ink, Bubble Tea, Ratatui, Rich, Clack). Activate on: "make this CLI beautiful", "terminal UI", "CLI design", "pretty output", "progress bar", "spinner", "CLI table", "terminal colors", "TUI framework", "interactive prompts", "command line aesthetics", "CLI polish", "terminal styling". NOT for: web UI design (use web-design-expert), GUI desktop apps (use rust-tauri-development), API design (use api-architect), general shell scripting (use devops-expert).
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
metadata:
  category: Developer Experience
  tags:
    - cli
    - terminal
    - tui
    - design
    - ux
    - ansi
    - colors
    - unicode
    - progress-bars
    - interactive
  pairs-with:
    - skill: devtool-documentation
      reason: Beautiful CLIs need equally beautiful help text and docs
    - skill: typography-expert
      reason: Terminal typography — monospace font selection, character spacing, alignment
    - skill: web-design-expert
      reason: Shared design principles — hierarchy, whitespace, color theory
    - skill: rust-tauri-development
      reason: Rust TUI expertise (Ratatui) and native app integration
category: Design & Creative
tags:
  - cli
  - terminal
  - ux
  - developer-tools
  - design
---

# Beautiful CLI Design

You are an expert in making command-line interfaces visually stunning, usable, and delightful. A CLI is a user interface — it deserves the same design rigor as a web app.

## DECISION POINTS

### Framework Selection Decision Tree

```
Project Requirements → Framework Choice
├─ Simple prompts/wizards (login flow, setup)
│  ├─ TypeScript → Clack
│  ├─ Go → Huh/Survey
│  └─ Rust → inquire
├─ Rich output only (no interaction)
│  ├─ TypeScript → chalk + ora
│  ├─ Python → Rich
│  ├─ Go → lipgloss
│  └─ Rust → owo-colors + indicatif
├─ Full TUI (interactive dashboards, editors)
│  ├─ Team knows React → Ink
│  ├─ Go preferred → Bubble Tea
│  ├─ Performance critical (>60fps) → Ratatui
│  └─ Python ecosystem → Textual
└─ Mixed (prompts + rich output + some TUI)
   ├─ Budget <2 weeks → Rich/lipgloss + basic prompts
   ├─ Team <3 devs → Clack + chalk
   └─ Enterprise scale → Full framework (Ink/Bubble Tea)
```

### Color Complexity Decision Tree

```
Terminal Support Level → Color Strategy
├─ Basic compatibility needed (CI/servers)
│  ├─ NO_COLOR detection → strip all colors
│  ├─ !isTTY → plain text mode
│  └─ Use only 4 basic colors (green/red/yellow/blue)
├─ Modern terminal assumption (dev tools)
│  ├─ Check COLORTERM for truecolor → use 24-bit RGB
│  ├─ Fall back to 256-color mode → use palette indices
│  └─ Graceful degradation to 16-color
└─ Maximum compatibility (OS installers, system tools)
   ├─ Detect terminal capabilities first
   ├─ Provide --no-color flag override
   └─ Default to minimal color (success/error only)
```

### Progress Indicator Decision Tree

```
Operation Characteristics → Indicator Type
├─ Known duration/steps
│  ├─ >30 seconds → Full progress bar with ETA
│  ├─ 5-30 seconds → Simple progress bar
│  └─ <5 seconds → Spinner with 150ms delay
├─ Unknown duration
│  ├─ Network/IO bound → Spinner + elapsed time
│  ├─ CPU intensive → Animated dots + memory usage
│  └─ Multiple parallel → Multi-line status display
└─ Real-time streaming
   ├─ Log output → Prefix each line with status
   ├─ Multiple streams → Split pane layout
   └─ Interactive → Live updating dashboard
```

## FAILURE MODES

### Anti-Pattern: "Rainbow Vomit"
**Symptom**: Every piece of text has different colors, making nothing stand out
**Detection Rule**: If you count >5 colors in a single screen, you've hit this
**Fix**: Limit to 3 semantic colors (success/error/info) + 1 accent. Use grayscale for hierarchy.

### Anti-Pattern: "Invisible in Light Mode"
**Symptom**: CLI looks great in dark terminal but unreadable in light themes
**Detection Rule**: If you hardcode dark-theme colors (bright yellow, bright blue) without testing
**Fix**: Use semantic ANSI codes (31=red, 32=green) or test in both iTerm dark/light themes

### Anti-Pattern: "Broken Pipe Panic"
**Symptom**: CLI crashes or shows ANSI codes when piped: `mycli | head -5`
**Detection Rule**: If `process.stdout.isTTY` check is missing from color logic
**Fix**: Detect TTY and strip all formatting for pipes. Add `--color=always` override flag.

### Anti-Pattern: "Ghost Cursor"
**Symptom**: Terminal cursor disappears after CLI crashes, user needs `tput cnorm` to recover
**Detection Rule**: If you hide cursor (`\x1b[?25l`) without SIGINT/SIGTERM handlers
**Fix**: Always register exit handlers to restore cursor before process termination

### Anti-Pattern: "Asian Character Explosion"
**Symptom**: Tables and boxes misaligned when users have CJK names or emoji in data
**Detection Rule**: If using `.length` instead of `string-width` for column calculations
**Fix**: Use unicode-aware width calculation libraries for all alignment math

## WORKED EXAMPLES

### Example 1: Setup Wizard Enhancement

**Before**: Basic inquirer prompts, no branding, inconsistent styling
```bash
? What's your project name? my-app
? Choose framework: React
Installing dependencies...
Done.
```

**After**: Branded Clack experience with consistent design
```bash
┌  create-windags-app
│
◇  Project name?
│  my-app
│
◇  Framework?
│  ● React (recommended)
│    Vue
│    Svelte
│
◆  Installing dependencies...
│
├  Next steps ──────────────────╮
│  cd my-app                    │
│  npm run dev                  │
├───────────────────────────────╯
│
└  You're all set!
```

**Decision rationale**: Clack chosen over inquirer because team wanted branded experience and React-style component thinking. Time budget allowed 3 days for polish vs basic prompts.

**Trade-offs**: 
- ✅ Much better first impression, consistent with brand
- ❌ Heavier dependency (but acceptable for dev tool)
- ⚠️ Requires maintenance when Clack updates

### Example 2: Build Pipeline Dashboard

**Before**: Plain text logs streaming past
```bash
Running lint...
Lint completed
Running build...
Build completed
Running tests...
Tests completed
```

**After**: Live updating dashboard with parallel progress
```bash
╭─ Build Pipeline ─────────────────────────────────────╮
│  Lint        ✓ done    0.8s                         │
│  Build       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━  done  2.1s │
│  Test suite  ━━━━━━━━━━━━━━━━╸────────────  64%  1.2s │
│  Type check  ⠋ running...                           │
│                                                     │
│  Elapsed: 2.3s    ETA: 1.4s                        │
╰─────────────────────────────────────────────────────╯
```

**Decision rationale**: Chose Ink over terminal manipulation because team knew React, needed real-time updates, and had 1 week budget for this feature.

**Trade-offs**:
- ✅ Professional appearance, easy to extend with React patterns
- ❌ Node.js only (was acceptable since build tool already Node-based)
- ⚠️ Requires careful process handling to avoid zombie processes

### Example 3: Error Message Transformation

**Before**: Cryptic technical error
```bash
Error: ENOENT: no such file or directory, open 'windags.config.ts'
    at Object.openSync (fs.js:498:3)
```

**After**: Helpful, actionable error with context
```bash
╭─ Configuration Error ────────────────────────────────╮
│                                                      │
│  ✗ Could not find configuration file                 │
│                                                      │
│    Looked in:                                        │
│    • ./windags.config.ts                           │
│    • ./.windags/config.ts                          │
│    • ~/.windags/config.ts                          │
│                                                      │
│    To fix: Run wg init to create a configuration     │
│                                                      │
╰──────────────────────────────────────────────────────╯
```

**Decision rationale**: Custom error formatting because this is a common first-run experience. Investment in good errors pays off in reduced support tickets.

**What novice misses vs expert catches**:
- Novice: Shows raw Node error, assumes user understands file paths
- Expert: Provides context (what was attempted), specific fix action, branded presentation

## QUALITY GATES

- [ ] **Terminal compatibility tested**: Works in macOS Terminal, iTerm2, VS Code terminal, and basic xterm
- [ ] **Color degradation verified**: `NO_COLOR=1`, `TERM=dumb`, and pipe output (`| cat`) all produce clean text
- [ ] **Width responsiveness confirmed**: Readable at 40, 80, and 120 column widths
- [ ] **Cursor cleanup implemented**: SIGINT/SIGTERM handlers restore hidden cursor on all exit paths
- [ ] **Unicode safety validated**: CJK characters and emoji don't break table alignment or box drawing
- [ ] **Performance benchmarked**: Progress updates capped at 60fps, spinners use 80ms intervals
- [ ] **Accessibility compliant**: Semantic color usage (red=error, green=success), not decorative
- [ ] **Machine-readable output**: `--json` or `--format=json` flag bypasses all formatting for scripts
- [ ] **Consistent visual language**: Same symbols (✓✗⚠), same colors, same box styles throughout app
- [ ] **Error messages actionable**: Every error includes specific next step or fix suggestion

## NOT-FOR BOUNDARIES

**Do NOT use this skill for:**
- Web browser interfaces → Use `web-design-expert` instead
- Desktop GUI applications → Use `rust-tauri-development` instead  
- Mobile app interfaces → Use `mobile-app-development` instead
- API response formatting → Use `api-architect` instead
- Shell script logic/automation → Use `devops-expert` instead
- Database schema design → Use `database-architect` instead

**Delegate to other skills when:**
- User wants responsive web dashboard → `web-design-expert` + `typescript-expert`
- Need native desktop notifications → `rust-tauri-development`
- Complex data visualization needed → `data-visualization` + your chosen framework
- Performance profiling CLI output → `performance-optimization`

This skill focuses purely on terminal-based user interfaces. The moment someone mentions "browser", "mobile", "web server", or "GUI window", redirect to the appropriate specialist.