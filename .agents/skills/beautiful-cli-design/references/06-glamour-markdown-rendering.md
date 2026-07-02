# Glamour -- Markdown Rendering in Terminal

**Package**: `charm.land/glamour/v2` (Go)
**Stars**: 3.4k
**License**: MIT
**GitHub**: https://github.com/charmbracelet/glamour
**Latest**: v2.0.0 (March 2026)
**Used by**: GitHub CLI (gh), GitLab CLI, Gitea CLI, Glow, Meteor

## What It Does

Glamour renders Markdown documents as styled, colorized ANSI output in the
terminal. It supports stylesheet-based theming so the same markdown can
look different depending on context (dark terminal, light terminal, plain text).

## Go Usage

```go
import "charm.land/glamour/v2"

// Quick render with built-in style
out, err := glamour.Render("# Hello\nWorld", "dark")
fmt.Print(out)

// Custom renderer with word wrap
r, _ := glamour.NewTermRenderer(
    glamour.WithWordWrap(40),
)
out, err := r.Render(markdownContent)
```

### Built-in Styles
- `"dark"` -- optimized for dark terminal backgrounds
- `"light"` -- optimized for light terminal backgrounds
- `"notty"` -- no ANSI codes, plain text
- `"ascii"` -- ASCII-safe rendering
- Custom JSON stylesheet

### Color Downsampling (v2)
```go
import (
    "charm.land/glamour/v2"
    "charm.land/lipgloss/v2"
)
r, _ := glamour.NewTermRenderer(glamour.WithWordWrap(40))
out, _ := r.Render(markdown)
lipgloss.Print(out) // auto-downsample colors
```

### Environment Configuration
```bash
GLAMOUR_STYLE=dark        # set default style
GLAMOUR_STYLE=/path/to/style.json  # custom stylesheet
```

```go
// Use environment config
glamour.RenderWithEnvironmentConfig(markdownText)

// Or in custom renderer
glamour.NewTermRenderer(glamour.WithEnvironmentConfig())
```

## JavaScript Equivalents

There is NO official JavaScript port of Glamour. Here are the alternatives:

### marked-terminal (Recommended)

The closest JS equivalent. Uses `marked` parser with a custom terminal renderer.

```bash
npm install marked marked-terminal
```

```javascript
import { marked } from 'marked';
import { markedTerminal } from 'marked-terminal';

marked.use(markedTerminal({
  // Options
  width: 80,
  reflowText: true,
  showSectionPrefix: true,
  tab: 2,
  // Color overrides
  firstHeading: chalk.bold.red,
  heading: chalk.bold.green,
  codespan: chalk.bgBlack.white,
  code: chalk.bgBlack,
  blockquote: chalk.italic.dim,
  href: chalk.blue.underline,
  listitem: chalk.dim,
  table: chalk.reset,
  paragraph: chalk.reset,
}));

const rendered = marked('# Hello\n\nWorld **bold** text');
console.log(rendered);
```

**Features:**
- Pretty tables
- Syntax highlighting for code blocks (JavaScript by default)
- Customizable colors and styles
- Supports all standard markdown elements
- 8M+ weekly downloads

### markdown-it-terminal

Plugin for markdown-it parser. Inspired by marked-terminal.

```bash
npm install markdown-it markdown-it-terminal
```

```javascript
const md = require('markdown-it')();
const terminal = require('markdown-it-terminal');
md.use(terminal);
console.log(md.render('# Hello'));
```

### cli-markdown

Simpler alternative for basic markdown rendering.

```bash
npm install cli-markdown
```

## Comparison: Glamour vs marked-terminal

| Feature | Glamour (Go) | marked-terminal (JS) |
|---------|-------------|---------------------|
| Stylesheet system | Full JSON stylesheets | Per-element overrides |
| Built-in themes | dark, light, notty, ascii | None (manual styling) |
| Color downsampling | Via lipgloss | Via chalk (auto) |
| Table rendering | Via lipgloss tables | Built-in |
| Code highlighting | Via chroma | Via cardinal/highlight.js |
| Env var config | GLAMOUR_STYLE | None |
| Word wrapping | Built-in | Built-in |
| Light/dark detection | Via lipgloss | Not built-in |
| Package size | Go binary (N/A) | ~50KB + marked dep |

## When to Use What

- **Need full Glamour parity in JS**: Use `marked-terminal` with chalk, closest equivalent
- **Rendering markdown in Ink apps**: Render with `marked-terminal`, wrap in `<Text>` with `{output}` (beware: ANSI codes inside Ink can conflict)
- **Simple markdown preview**: `cli-markdown` is lightest option
- **Rich markdown viewer app**: Consider shelling out to `glow` (Charm's markdown viewer CLI)
