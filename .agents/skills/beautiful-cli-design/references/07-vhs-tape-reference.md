# VHS -- Terminal GIF Recording as Code

**Package**: `vhs` (CLI tool, Go binary)
**Stars**: 15k+
**License**: MIT
**GitHub**: https://github.com/charmbracelet/vhs
**Requires**: `ttyd` and `ffmpeg` on PATH

## Installation

```bash
# macOS/Linux
brew install vhs

# Arch
pacman -S vhs

# Nix
nix-env -iA nixpkgs.vhs

# Windows
scoop install vhs

# Docker (dependencies included)
docker run --rm -v $PWD:/vhs ghcr.io/charmbracelet/vhs demo.tape

# Go
go install github.com/charmbracelet/vhs@latest
```

## Quick Start

```bash
vhs new demo.tape     # create template
vim demo.tape         # edit
vhs demo.tape         # generate GIF
vhs record > out.tape # record terminal session
vhs publish demo.gif  # share on vhs.charm.sh
vhs serve             # run SSH server
vhs themes            # list all themes
vhs manual            # full reference
```

## Complete Command Reference

### Output

Specify output file(s). Multiple outputs allowed.

```elixir
Output demo.gif       # animated GIF
Output demo.mp4       # video
Output demo.webm      # web video
Output frames/        # PNG sequence directory
Output golden.ascii   # ASCII text (for CI golden tests)
Output golden.txt     # text output
```

### Require

Fail early if dependency missing. Must be at top of file.

```elixir
Require gum
Require glow
Require node
```

### Type

Emulate typing characters.

```elixir
Type "echo 'Hello World'"
Type@500ms "Slow typing"       # override speed per command
Type `VAR="Escaped quotes"`    # backtick escaping
```

### Key Commands

All key commands support optional `@time` and repeat `count`:
```
Key[@<time>] [count]
```

```elixir
# Special keys
Enter                    # press enter
Enter 3                  # press enter 3 times
Backspace 18             # delete 18 characters
Tab                      # press tab
Tab@500ms 2              # press tab twice, 500ms apart
Space 10                 # 10 spaces
Escape                   # escape key

# Arrow keys
Up 2
Down 2
Left
Right

# Navigation
PageUp 3
PageDown 5
Home
End

# Modifiers
Ctrl+C                   # ctrl+c
Ctrl+R                   # reverse search
Ctrl+Alt+Delete
Ctrl+Shift+F

# Scroll (viewport, not keys)
ScrollUp 10
ScrollDown 4
ScrollDown@100ms 12
```

### Sleep

Pause without interaction.

```elixir
Sleep 0.5               # 500ms
Sleep 2                 # 2 seconds
Sleep 100ms             # 100ms
Sleep 1s                # 1 second
Sleep 500ms             # 500ms
```

### Wait

Wait for content to appear on screen. Default: regex `/>$/`, timeout 15s, scope Line.

```elixir
Wait                      # default: wait for prompt
Wait /World/              # wait for "World" to appear
Wait+Screen /World/       # search entire screen
Wait+Line /World/         # search last line only (default)
Wait@10ms /World/         # check every 10ms
Wait+Line@10ms /World/    # combined
```

### Hide / Show

Control frame capture.

```elixir
# Setup (hidden)
Hide
Type "go build -o example . && clear"
Enter
Show

# Record the demo
Type "./example"
Enter
Sleep 3s

# Cleanup (hidden)
Hide
Type "rm example"
Enter
```

### Screenshot

Capture current frame as PNG.

```elixir
Screenshot examples/screenshot.png
```

### Copy / Paste

Clipboard operations.

```elixir
Copy "https://github.com/charmbracelet"
Type "open "
Sleep 500ms
Paste
```

### Source

Include commands from another tape file.

```elixir
Source config.tape
Source setup.tape
```

### Env

Set environment variables.

```elixir
Env HELLO "WORLD"
Env NO_COLOR "1"
Env TERM "xterm-256color"
```

## Complete Settings Reference

All settings use `Set` command. Must be at top of file (except TypingSpeed).

### Terminal Configuration

```elixir
Set Shell "bash"              # shell to use (bash, zsh, fish, powershell)
Set Shell "fish"

Set FontSize 14               # font size in pixels
Set FontFamily "Monaspace Neon"  # font family name

Set Width 1200                # terminal width in pixels
Set Height 600                # terminal height in pixels

Set LetterSpacing 1           # tracking (pixels between letters)
Set LineHeight 1.2            # line spacing multiplier
```

### Typing

```elixir
Set TypingSpeed 50ms          # delay per character
Set TypingSpeed 0.1           # 100ms per character
Set TypingSpeed 500ms         # slow typing
# Can be set/changed anywhere in tape (not just top)
```

### Appearance

```elixir
Set Padding 20                # terminal frame padding (pixels)
Set Margin 60                 # video margin (pixels)
Set MarginFill "#6B50FF"      # margin background color
Set BorderRadius 10           # rounded corners (pixels)
Set WindowBar Colorful        # window bar style
Set WindowBar ColorfulRight   # dots on right
Set WindowBar Rings           # ring-style dots
Set WindowBar RingsRight      # rings on right
Set CursorBlink false         # disable cursor blink
```

### Recording

```elixir
Set Framerate 60              # capture framerate
Set PlaybackSpeed 1.0         # 1.0 = normal, 2.0 = 2x fast, 0.5 = 2x slow
Set LoopOffset 5              # start GIF loop at frame 5
Set LoopOffset 50%            # start GIF loop at 50%
```

### Themes

```elixir
# By name
Set Theme "Catppuccin Frappe"
Set Theme "Dracula"
Set Theme "One Dark"
Set Theme "GitHub Dark"

# Custom JSON
Set Theme { "name": "Custom", "black": "#535178", "red": "#ef6487", "green": "#5eca89", "yellow": "#fdd877", "blue": "#65aef7", "magenta": "#aa7ff0", "cyan": "#43c1be", "white": "#ffffff", "brightBlack": "#535178", "brightRed": "#ef6487", "brightGreen": "#5eca89", "brightYellow": "#fdd877", "brightBlue": "#65aef7", "brightMagenta": "#aa7ff0", "brightCyan": "#43c1be", "brightWhite": "#ffffff", "background": "#29283b", "foreground": "#b3b0d6", "selection": "#3d3c58", "cursor": "#b3b0d6" }
```

View all available themes: `vhs themes`

## Complete Example Tape

```elixir
# demo.tape -- Product demo recording
Require node
Require gum

Output demo.gif
Output demo.mp4

Set Shell "zsh"
Set FontSize 20
Set FontFamily "Monaspace Neon"
Set Width 1200
Set Height 600
Set Padding 20
Set Margin 30
Set MarginFill "#1a1a2e"
Set BorderRadius 8
Set WindowBar Colorful
Set Theme "Catppuccin Frappe"
Set TypingSpeed 50ms
Set Framerate 30
Set PlaybackSpeed 1.0
Set CursorBlink true
Set LoopOffset 20%

# Hidden setup
Hide
Type "cd /tmp/demo && clear"
Enter
Sleep 500ms
Show

# Demo
Type "wg next-move 'build a REST API'"
Sleep 300ms
Enter

Wait+Screen /DAG/
Sleep 2s
Screenshot screenshots/dag-output.png

Type "q"
Sleep 1s
```

## CI Integration

```yaml
# GitHub Actions
- uses: charmbracelet/vhs-action@v2
  with:
    path: demo.tape
```

Golden file testing:
```elixir
Output golden.ascii
# ... commands ...
# Then diff golden.ascii against expected output in CI
```

## VHS Server (SSH)

```bash
# Start server
VHS_PORT=1976 VHS_HOST=0.0.0.0 vhs serve

# Remote client
ssh vhs.example.com < demo.tape > demo.gif
```

Config env vars: `VHS_PORT`, `VHS_HOST`, `VHS_GID`, `VHS_UID`, `VHS_KEY_PATH`, `VHS_AUTHORIZED_KEYS_PATH`

## Node.js Integration

Call VHS from Node.js for automated demo generation:

```javascript
const { execSync } = require('child_process');
const fs = require('fs');

// Generate tape programmatically
const tape = `
Output demo.gif
Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 600
Set Theme "Catppuccin Frappe"

Type "node my-cli.js --help"
Enter
Sleep 2s
`;

fs.writeFileSync('/tmp/demo.tape', tape);
execSync('vhs /tmp/demo.tape', { stdio: 'inherit' });
```
