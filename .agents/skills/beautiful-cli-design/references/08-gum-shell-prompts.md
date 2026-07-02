# Gum -- Interactive Shell Prompts from Any Language

**Package**: `gum` (CLI tool, Go binary)
**Stars**: 18k+
**License**: MIT
**GitHub**: https://github.com/charmbracelet/gum

## Why Gum Matters for Node.js/TypeScript

Gum is the fastest path to gorgeous terminal prompts WITHOUT Ink, React, or any
framework. Call it via `execSync` from Node.js and get Bubble Tea / Lip Gloss
quality prompts in a single line.

## Installation

```bash
brew install gum       # macOS/Linux
pacman -S gum          # Arch
dnf install gum        # Fedora
scoop install charm-gum # Windows
go install github.com/charmbracelet/gum@latest
```

## All Commands

### input -- Single Line Text

```bash
gum input --placeholder "Enter name..." --value "default" --width 50
gum input --password   # masked input
gum input --prompt "? " --cursor.foreground "#FF0" --prompt.foreground "#0FF"
```

### write -- Multi-line Text

```bash
gum write --placeholder "Details..." --width 80 --height 10
# Ctrl+D to finish
```

### choose -- Single Select

```bash
gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore"
gum choose --height 15 --cursor ">" --cursor.foreground "212"
gum choose --limit 5 < options.txt         # max 5 selections
gum choose --no-limit < options.txt        # unlimited multi-select
gum choose --header "Pick a flavor:"
```

### filter -- Fuzzy Search

```bash
echo -e "Apple\nBanana\nCherry" | gum filter
gum filter < items.txt
gum filter --limit 3 < items.txt           # multi-select with limit
gum filter --no-limit < items.txt          # unlimited
gum filter --placeholder "Search..." --height 20
```

### confirm -- Yes/No

```bash
gum confirm "Delete files?"                # exits 0 (yes) or 1 (no)
gum confirm "Deploy?" && deploy.sh || echo "Cancelled"
gum confirm --affirmative "Yes!" --negative "No way"
```

### file -- File Picker

```bash
gum file .                                 # pick from current dir
gum file $HOME                             # pick from home
gum file --all                             # show hidden files
gum file --directory                       # directories only
```

### spin -- Spinner

```bash
gum spin --spinner dot --title "Installing..." -- npm install
gum spin --spinner line --title "Building..." --show-output -- make build
```

**Spinner types**: `line`, `dot`, `minidot`, `jump`, `pulse`, `points`, `globe`, `moon`, `monkey`, `meter`, `hamburger`

### style -- Text Styling

```bash
gum style \
  --foreground 212 \
  --border-foreground 212 \
  --border double \
  --align center \
  --width 50 \
  --margin "1 2" \
  --padding "2 4" \
  'Bubble Gum (1 cent)' 'So sweet and fresh!'
```

### join -- Layout Composition

```bash
# Create styled blocks
I=$(gum style --padding "1 5" --border double --border-foreground 212 "I")
LOVE=$(gum style --padding "1 4" --border double --border-foreground 57 "LOVE")
BUBBLE=$(gum style --padding "1 8" --border double --border-foreground 255 "Bubble")
GUM=$(gum style --padding "1 5" --border double --border-foreground 240 "Gum")

# Join them
I_LOVE=$(gum join "$I" "$LOVE")
BUBBLE_GUM=$(gum join "$BUBBLE" "$GUM")
gum join --align center --vertical "$I_LOVE" "$BUBBLE_GUM"
```

### format -- Markdown/Template/Emoji Rendering

```bash
# Markdown
gum format -- "# Hello" "- Item 1" "- Item 2"
echo "# Title\n\nBody" | gum format

# Code highlighting
cat main.go | gum format -t code

# Templates (termenv helpers)
echo '{{ Bold "Tasty" }} {{ Italic "Bubble" }} {{ Color "99" "0" " Gum " }}' | gum format -t template

# Emoji
echo 'I :heart: CLIs :candy:' | gum format -t emoji
```

### table -- Tabular Data Selection

```bash
gum table < data.csv | cut -d ',' -f 1
```

### pager -- Scrollable Viewer

```bash
gum pager < README.md
cat large-file.log | gum pager
```

### log -- Structured Logging

```bash
gum log --structured --level debug "Starting..." name app.ts
gum log --structured --level error "Failed" err "timeout"
gum log --time rfc822 --level info "Processing complete"
```

**Levels**: debug, info, warn, error

## Customization System

### Flags

Every visual aspect is customizable via flags:

```bash
gum input \
  --cursor.foreground "#FF0" \
  --prompt.foreground "#0FF" \
  --placeholder "What's up?" \
  --prompt "* " \
  --width 80 \
  --value "default"
```

### Environment Variables

Every flag has an env var equivalent:

```bash
export GUM_INPUT_CURSOR_FOREGROUND="#FF0"
export GUM_INPUT_PROMPT_FOREGROUND="#0FF"
export GUM_INPUT_PLACEHOLDER="What's up?"
export GUM_INPUT_PROMPT="* "
export GUM_INPUT_WIDTH=80
gum input  # uses env vars
```

Pattern: `GUM_<COMMAND>_<FLAG>` where dots become underscores.

## Node.js Integration Patterns

### Basic: execSync Wrapper

```javascript
const { execSync } = require('child_process');

function gumInput(options = {}) {
  const args = ['gum', 'input'];
  if (options.placeholder) args.push('--placeholder', JSON.stringify(options.placeholder));
  if (options.value) args.push('--value', JSON.stringify(options.value));
  if (options.password) args.push('--password');
  if (options.width) args.push('--width', String(options.width));
  return execSync(args.join(' '), { encoding: 'utf-8', stdio: ['inherit', 'pipe', 'inherit'] }).trim();
}

function gumChoose(choices, options = {}) {
  const args = ['gum', 'choose', ...choices.map(c => JSON.stringify(c))];
  if (options.height) args.push('--height', String(options.height));
  if (options.header) args.push('--header', JSON.stringify(options.header));
  return execSync(args.join(' '), { encoding: 'utf-8', stdio: ['inherit', 'pipe', 'inherit'] }).trim();
}

function gumConfirm(message) {
  try {
    execSync(`gum confirm ${JSON.stringify(message)}`, { stdio: 'inherit' });
    return true;
  } catch {
    return false;
  }
}

function gumSpin(title, command) {
  return execSync(`gum spin --spinner dot --title ${JSON.stringify(title)} -- ${command}`, {
    encoding: 'utf-8',
    stdio: ['inherit', 'pipe', 'inherit'],
  }).trim();
}

// Usage
const name = gumInput({ placeholder: 'Your name?' });
const framework = gumChoose(['React', 'Vue', 'Svelte'], { header: 'Framework:' });
if (gumConfirm(`Create ${name} with ${framework}?`)) {
  gumSpin('Installing...', 'npm install');
}
```

### Advanced: Spawn for Streaming

```javascript
const { spawnSync } = require('child_process');

function gumFilter(items, options = {}) {
  const args = ['filter'];
  if (options.placeholder) args.push('--placeholder', options.placeholder);
  if (options.height) args.push('--height', String(options.height));
  if (options.limit) args.push('--limit', String(options.limit));

  const result = spawnSync('gum', args, {
    input: items.join('\n'),
    encoding: 'utf-8',
    stdio: ['pipe', 'pipe', 'inherit'],
  });
  return result.stdout.trim().split('\n').filter(Boolean);
}

const selected = gumFilter(['apple', 'banana', 'cherry', 'date'], {
  placeholder: 'Pick fruits...',
  limit: 2,
});
```

### Conventional Commit Script (Classic Gum Pattern)

```bash
#!/bin/bash
TYPE=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
SCOPE=$(gum input --placeholder "scope")
test -n "$SCOPE" && SCOPE="($SCOPE)"
SUMMARY=$(gum input --value "$TYPE$SCOPE: " --placeholder "Summary of this change")
DESCRIPTION=$(gum write --placeholder "Details of this change (CTRL+D to finish)")
gum confirm "Commit changes?" && git commit -m "$SUMMARY" -m "$DESCRIPTION"
```

## Gum vs Ink vs @inquirer/prompts vs @clack/prompts

| Feature | Gum | Ink | @inquirer/prompts | @clack/prompts |
|---------|-----|-----|-------------------|----------------|
| Language | Any (CLI) | TypeScript/React | TypeScript | TypeScript |
| Install | Binary | npm | npm | npm |
| Dependency size | 0 (binary) | ~2MB | ~500KB | ~100KB |
| Learning curve | Shell scripting | React | Callbacks | Callbacks |
| Real-time UI | No | Yes (React) | No | No |
| Theming | Flags/env vars | React context | chalk | Built-in |
| CI friendly | Yes | Partial | Yes | Yes |
| Pipe-friendly | Excellent | No | Partial | Partial |
| Requires process | Yes (exec) | No (in-process) | No | No |
| Best for | Shell scripts, quick prompts | Full TUI apps | Complex flows | Modern prompts |
