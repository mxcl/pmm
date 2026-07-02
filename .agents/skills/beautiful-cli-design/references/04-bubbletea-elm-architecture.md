# Bubble Tea -- The Elm Architecture for Terminal Apps

**Package**: `charm.land/bubbletea/v2` (Go)
**Stars**: 30k+ (one of the most popular Go TUI frameworks)
**License**: MIT
**GitHub**: https://github.com/charmbracelet/bubbletea
**Used by**: 18,000+ applications including CockroachDB, GitHub CLI, AWS tools, NVIDIA, Azure, MinIO

## The Elm Architecture (Model-Update-View)

Bubble Tea implements The Elm Architecture from Elm lang. This is the core
design pattern that should inform how you think about terminal apps even
when using Ink/React.

### Three Core Methods

```go
type Model interface {
    Init() tea.Cmd           // Return initial command (or nil)
    Update(tea.Msg) (Model, tea.Cmd)  // Handle events, return new state
    View() tea.View          // Render UI from current state
}
```

### 1. Model -- Application State

A struct holding ALL application state. Pure data, no side effects.

```go
type model struct {
    choices  []string
    cursor   int
    selected map[int]struct{}
    loading  bool
    err      error
}
```

### 2. Update -- Event Handler

Pure function: takes current model + message, returns new model + optional command.
Messages are the ONLY way state changes. This makes state transitions auditable.

```go
func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.KeyPressMsg:
        switch msg.String() {
        case "ctrl+c", "q":
            return m, tea.Quit
        case "up", "k":
            if m.cursor > 0 { m.cursor-- }
        case "down", "j":
            if m.cursor < len(m.choices)-1 { m.cursor++ }
        case "enter", "space":
            _, ok := m.selected[m.cursor]
            if ok {
                delete(m.selected, m.cursor)
            } else {
                m.selected[m.cursor] = struct{}{}
            }
        }
    }
    return m, nil
}
```

### 3. View -- Declarative Rendering

Pure function: takes model, returns string. No side effects. Bubble Tea
handles all the diffing and re-rendering.

```go
func (m model) View() tea.View {
    s := "What should we buy?\n\n"
    for i, choice := range m.choices {
        cursor := " "
        if m.cursor == i { cursor = ">" }
        checked := " "
        if _, ok := m.selected[i]; ok { checked = "x" }
        s += fmt.Sprintf("%s [%s] %s\n", cursor, checked, choice)
    }
    s += "\nPress q to quit.\n"
    return tea.NewView(s)
}
```

### Running the Program

```go
p := tea.NewProgram(initialModel())
result, err := p.Run()
```

## Key Concepts for TypeScript/Ink Developers

### Messages (Msgs) -- Like Actions/Events

In Bubble Tea, messages are the equivalent of Redux actions or React events.
They are typed and drive ALL state changes.

```go
type tea.KeyPressMsg       // keyboard input
type tea.WindowSizeMsg     // terminal resize
type tea.MouseMsg          // mouse events
type tea.BackgroundColorMsg // terminal background detected
type customMsg struct{}     // your own messages
```

**Mapping to Ink/React:**
- `tea.KeyPressMsg` --> `useInput()` hook
- `tea.WindowSizeMsg` --> `useWindowSize()` hook
- Custom Msgs --> React state updates via `useState`/`useReducer`

### Commands (Cmds) -- Like Effects/Thunks

Commands are functions that produce messages asynchronously. They are how
side effects happen (HTTP requests, timers, file I/O).

```go
func fetchURL(url string) tea.Cmd {
    return func() tea.Msg {
        resp, err := http.Get(url)
        if err != nil { return errMsg{err} }
        return responseMsg{resp}
    }
}
```

**Mapping to Ink/React:**
- Commands --> `useEffect()` hooks
- `tea.Batch(cmd1, cmd2)` --> Multiple `useEffect` hooks running in parallel
- `tea.Sequence(cmd1, cmd2)` --> Chained effects

### Subscriptions -- Like Event Listeners

Long-running event sources (tickers, file watchers, etc).

**Mapping to Ink/React:**
- Subscriptions --> `useEffect()` with cleanup (setInterval + clearInterval)

## Pattern Transfer: Bubble Tea to Ink

### Bubble Tea Pattern: Reducer-like Update

```go
// Bubble Tea
func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tickMsg:
        m.progress += 0.1
        if m.progress >= 1.0 {
            return m, tea.Quit
        }
        return m, tick()
    }
    return m, nil
}
```

### Equivalent Ink Pattern: useReducer + useEffect

```tsx
// Ink/React equivalent
function App() {
  const [progress, setProgress] = useState(0);
  const { exit } = useApp();

  useEffect(() => {
    const timer = setInterval(() => {
      setProgress(p => {
        if (p >= 1.0) {
          clearInterval(timer);
          exit();
          return p;
        }
        return p + 0.1;
      });
    }, 100);
    return () => clearInterval(timer);
  }, []);

  return <ProgressBar value={progress * 100} />;
}
```

### Bubble Tea Pattern: Component Composition (Bubbles)

```go
// Bubble Tea uses "Bubbles" (reusable Models)
type model struct {
    textInput textinput.Model
    spinner   spinner.Model
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    var cmds []tea.Cmd
    m.textInput, cmd1 = m.textInput.Update(msg)
    m.spinner, cmd2 = m.spinner.Update(msg)
    cmds = append(cmds, cmd1, cmd2)
    return m, tea.Batch(cmds...)
}
```

### Equivalent Ink Pattern: React Components

```tsx
// Ink equivalent -- composition is natural in React
function App() {
  return (
    <Box flexDirection="column">
      <TextInput placeholder="Name..." onSubmit={handleSubmit} />
      <Spinner label="Processing" />
    </Box>
  );
}
```

## Key Bubble Tea Features

- **Cell-based renderer**: High performance terminal rendering with diff-based updates
- **Built-in color downsampling**: Automatic degradation for terminal capabilities
- **Declarative views**: View function describes entire UI from state
- **Alt screen mode**: Full-screen takeover of terminal
- **Mouse support**: Click, scroll, motion events
- **Clipboard support**: Native copy/paste integration
- **Kitty keyboard protocol**: Extended key events (press/repeat/release)

## Companion Libraries

| Library | Purpose | Ink Equivalent |
|---------|---------|----------------|
| **Bubbles** | Pre-built components (text input, viewport, spinner, etc) | `@inkjs/ui` |
| **Lip Gloss** | Styling and layout | `@charmland/lipgloss` or chalk |
| **Harmonica** | Spring animations | `react-spring` or CSS transitions |
| **BubbleZone** | Mouse event tracking for components | Ink's built-in mouse support |

## Debugging

```go
// Log to file (stdout is occupied by TUI)
f, err := tea.LogToFile("debug.log", "debug")
defer f.Close()

// Then: tail -f debug.log
```

```go
// Delve debugger (headless mode required)
// Terminal 1:
dlv debug --headless --api-version=2 --listen=127.0.0.1:43000 .
// Terminal 2:
dlv connect 127.0.0.1:43000
```
