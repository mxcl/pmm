# Huh? -- Terminal Forms Library

**Package**: `charm.land/huh/v2` (Go)
**Stars**: 6.7k
**License**: MIT
**GitHub**: https://github.com/charmbracelet/huh
**Inspired by**: AlecAivazis/survey (Go)
**Built on**: Bubble Tea + Lip Gloss

## What It Does

Interactive forms and prompts in the terminal. Groups fields into pages,
supports validation, theming, dynamic fields, accessibility, and embeds
directly into Bubble Tea applications.

## Go API

### Form Structure

```go
form := huh.NewForm(
    huh.NewGroup(
        huh.NewSelect[string]().
            Title("Choose burger").
            Options(
                huh.NewOption("Classic", "classic"),
                huh.NewOption("Chickwich", "chickwich"),
            ).
            Value(&burger),

        huh.NewMultiSelect[string]().
            Title("Toppings").
            Options(
                huh.NewOption("Lettuce", "lettuce").Selected(true),
                huh.NewOption("Tomatoes", "tomatoes"),
                huh.NewOption("Cheese", "cheese"),
            ).
            Limit(4).
            Value(&toppings),
    ),

    huh.NewGroup(
        huh.NewInput().
            Title("Name?").
            Value(&name).
            Validate(func(s string) error {
                if s == "" { return errors.New("Required") }
                return nil
            }),

        huh.NewText().
            Title("Special Instructions").
            CharLimit(400).
            Value(&instructions),

        huh.NewConfirm().
            Title("15% off?").
            Value(&discount),
    ),
)

err := form.Run()
```

### Field Types

**Input** -- single line text
```go
huh.NewInput().
    Title("What's for lunch?").
    Prompt("?").
    Placeholder("type here...").
    Validate(isFood).
    Value(&lunch)
```

**Text** -- multi-line text
```go
huh.NewText().
    Title("Tell a story").
    CharLimit(400).
    Validate(checkPlagiarism).
    Value(&story)
```

**Select** -- single choice (generic type)
```go
huh.NewSelect[string]().
    Title("Country").
    Options(
        huh.NewOption("United States", "US"),
        huh.NewOption("Germany", "DE"),
    ).
    Value(&country)

// Integer values
huh.NewSelect[int]().
    Title("Sauce level").
    Options(
        huh.NewOption("None", 0),
        huh.NewOption("A lot", 2),
    ).
    Value(&sauceLevel)
```

**MultiSelect** -- multiple choices
```go
huh.NewMultiSelect[string]().
    Title("Toppings").
    Options(huh.NewOptions("Lettuce", "Tomato", "Cheese")...).
    Limit(4).
    Value(&toppings)
```

**Confirm** -- yes/no
```go
huh.NewConfirm().
    Title("Are you sure?").
    Affirmative("Yes!").
    Negative("No.").
    Value(&confirm)
```

### Standalone Field Execution

```go
var name string
huh.NewInput().Title("Name?").Value(&name).Run()
```

### Dynamic Forms

Fields recompute based on bindings to other values:

```go
huh.NewSelect[string]().
    Value(&state).
    TitleFunc(func() string {
        switch country {
        case "US": return "State"
        case "Canada": return "Province"
        default: return "Territory"
        }
    }, &country).  // recompute when country changes
    OptionsFunc(func() []huh.Option[string] {
        return huh.NewOptions(fetchStates(country)...)
    }, &country)   // recompute when country changes
```

### Themes

5 built-in themes:
- **Charm** -- branded Charm look
- **Dracula** -- Dracula color scheme
- **Catppuccin** -- Catppuccin palette
- **Base 16** -- standard base16
- **Default** -- minimal

```go
form.WithTheme(huh.ThemeDracula())
form.WithTheme(huh.ThemeCatppuccin())
```

### Accessibility

```go
accessibleMode := os.Getenv("ACCESSIBLE") != ""
form.WithAccessible(accessibleMode)
```
Drops TUI in favor of standard prompts for screen readers.

### Bubble Tea Integration

```go
type Model struct {
    form *huh.Form  // huh.Form IS a tea.Model
}

func (m Model) Init() tea.Cmd { return m.form.Init() }

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    form, cmd := m.form.Update(msg)
    if f, ok := form.(*huh.Form); ok { m.form = f }
    return m, cmd
}

func (m Model) View() string {
    if m.form.State == huh.StateCompleted {
        return fmt.Sprintf("Class: %s, Level: %d",
            m.form.GetString("class"),
            m.form.GetInt("level"))
    }
    return m.form.View()
}
```

### Spinner (Bonus)

```go
import "charm.land/huh/v2/spinner"

// Action style
spinner.New().
    Title("Making burger...").
    Action(makeBurger).
    Run()

// Context style (with goroutine)
go makeBurger()
spinner.New().
    Type(spinner.Line).
    Title("Making burger...").
    Context(ctx).
    Run()
```

## JavaScript Equivalents Comparison

### @clack/prompts (Most Similar)

Most similar to Huh? in design philosophy: beautiful defaults, grouped prompts, built-in styling.

```javascript
import { intro, outro, text, select, multiselect, confirm, spinner, group } from '@clack/prompts';

intro('create-app');

const answers = await group({
  name: () => text({ message: 'Project name?', validate: (v) => !v ? 'Required' : undefined }),
  framework: () => select({
    message: 'Framework?',
    options: [
      { value: 'react', label: 'React' },
      { value: 'vue', label: 'Vue' },
    ],
  }),
  features: () => multiselect({
    message: 'Features?',
    options: [
      { value: 'ts', label: 'TypeScript' },
      { value: 'eslint', label: 'ESLint' },
    ],
  }),
  confirm: () => confirm({ message: 'Continue?' }),
});

const s = spinner();
s.start('Installing...');
await install();
s.stop('Installed');

outro('Done!');
```

### @inquirer/prompts (Most Mature)

More established, plugin ecosystem, but less beautiful out of the box.

```javascript
import { input, select, checkbox, confirm } from '@inquirer/prompts';

const name = await input({ message: 'Name?' });
const framework = await select({
  message: 'Framework?',
  choices: [
    { name: 'React', value: 'react' },
    { name: 'Vue', value: 'vue' },
  ],
});
const ok = await confirm({ message: 'Continue?' });
```

## Comparison Matrix

| Feature | Huh? (Go) | @clack/prompts | @inquirer/prompts | Ink + @inkjs/ui |
|---------|-----------|----------------|-------------------|-----------------|
| Grouped forms | Yes (pages) | Yes (group()) | Sequential only | Manual |
| Validation | Built-in | Built-in | Built-in | Manual |
| Dynamic fields | TitleFunc/OptionsFunc | No | No | React state |
| Themes | 5 built-in | 1 (beautiful) | None | ThemeProvider |
| Accessibility | Built-in toggle | No | No | ARIA support |
| Bubble Tea embed | Native | N/A | N/A | N/A (IS React) |
| Spinner | Built-in | Built-in | Separate | @inkjs/ui |
| Cancel handling | Built-in | isCancel() | Throws | useApp().exit() |
| Custom types | Generic[T] | No | Plugin system | Any React |
| Live preview | No | No | No | Yes (React) |

## When to Use What

- **Quick prompts in a script**: Gum (shell) or @clack/prompts (Node.js)
- **Setup wizard**: @clack/prompts (beautiful defaults) or Huh? (Go)
- **Complex forms with dependencies**: Huh? (dynamic fields) or Ink (React state)
- **Embedded in TUI app**: Huh? (Bubble Tea) or @inkjs/ui (Ink)
- **Maximum plugin ecosystem**: @inquirer/prompts
- **No-dependency prompts**: Gum via execSync
