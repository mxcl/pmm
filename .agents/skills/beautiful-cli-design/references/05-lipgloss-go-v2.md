# Lip Gloss v2 -- Go Styling Library (Complete Reference)

**Package**: `charm.land/lipgloss/v2` (Go)
**Stars**: 10k+
**License**: MIT
**GitHub**: https://github.com/charmbracelet/lipgloss

This is the authoritative Go API. The JS port (@charmland/lipgloss) mirrors
this API. Understanding the Go version helps predict what JS features will
land next.

## Style Methods (Complete List)

### Inline Formatting
```go
s := lipgloss.NewStyle().
    Bold(true).
    Italic(true).
    Faint(true).
    Blink(true).
    Strikethrough(true).
    Underline(true).
    Reverse(true)
```

### Underline Styles (NEW in v2)
```go
s := lipgloss.NewStyle().
    UnderlineStyle(lipgloss.UnderlineCurly).
    UnderlineColor(lipgloss.Color("#FF0000"))
```
Available: `UnderlineNone`, `UnderlineSingle`, `UnderlineDouble`, `UnderlineCurly`, `UnderlineDotted`, `UnderlineDashed`

### Hyperlinks (NEW in v2)
```go
s := lipgloss.NewStyle().
    Foreground(lipgloss.Color("#7B2FBE")).
    Hyperlink("https://charm.land")
lipgloss.Println(s.Render("Visit Charm"))
```

### Block-Level Formatting
```go
// Padding (CSS shorthand pattern)
lipgloss.NewStyle().Padding(2)          // all sides
lipgloss.NewStyle().Padding(2, 4)       // vertical, horizontal
lipgloss.NewStyle().Padding(1, 4, 2)    // top, horizontal, bottom
lipgloss.NewStyle().Padding(2, 4, 3, 1) // clockwise from top

// Individual padding
lipgloss.NewStyle().PaddingTop(2).PaddingRight(4).PaddingBottom(2).PaddingLeft(4)

// Custom fill characters
lipgloss.NewStyle().PaddingChar('.').MarginChar('#')

// Margins (same shorthand pattern)
lipgloss.NewStyle().Margin(2, 4)
lipgloss.NewStyle().MarginTop(2).MarginRight(4)
```

### Alignment
```go
lipgloss.NewStyle().
    Width(24).
    Align(lipgloss.Left).
    Align(lipgloss.Right).
    Align(lipgloss.Center)
```

### Dimensions
```go
lipgloss.NewStyle().
    Width(24).
    Height(32).
    MaxWidth(40).
    MaxHeight(20).
    Inline(true)     // force single line
```

### Tab Handling
```go
lipgloss.NewStyle().TabWidth(4)   // convert tabs to 4 spaces (default)
lipgloss.NewStyle().TabWidth(2)   // 2 spaces
lipgloss.NewStyle().TabWidth(0)   // remove tabs
lipgloss.NewStyle().TabWidth(lipgloss.NoTabConversion) // leave intact
```

## All 10 Border Styles

```go
lipgloss.NormalBorder()          // ─│┌┐└┘  (thin lines)
lipgloss.RoundedBorder()         // ─│╭╮╰╯  (rounded corners)
lipgloss.ThickBorder()           // ━┃┏┓┗┛  (heavy lines)
lipgloss.DoubleBorder()          // ═║╔╗╚╝  (double lines)
lipgloss.HiddenBorder()          // invisible (space-consuming)
lipgloss.BlockBorder()           // ████████  (full block)
lipgloss.InnerHalfBlockBorder()  // ▄▐▗▖▀▌▝▘ (inner half blocks)
lipgloss.OuterHalfBlockBorder()  // ▀▌▛▜▄▐▙▟ (outer half blocks)
lipgloss.MarkdownBorder()        // | - (markdown tables)
lipgloss.ASCIIBorder()           // + - | (maximum compat)
```

### Custom Borders
```go
myBorder := lipgloss.Border{
    Top: "._.:*:", Bottom: "._.:*:",
    Left: "|*", Right: "|*",
    TopLeft: "*", TopRight: "*",
    BottomLeft: "*", BottomRight: "*",
}

// Gradient borders (NEW in v2)
s := lipgloss.NewStyle().
    Border(lipgloss.RoundedBorder()).
    BorderForegroundBlend(lipgloss.Color("#FF0000"), lipgloss.Color("#0000FF"))
```

### Border Configuration
```go
lipgloss.NewStyle().
    BorderStyle(lipgloss.NormalBorder()).
    BorderForeground(lipgloss.Color("63")).
    BorderBackground(lipgloss.Color("0")).
    BorderTop(true).
    BorderBottom(true).
    BorderLeft(true).
    BorderRight(true)

// Shorthand
lipgloss.NewStyle().Border(lipgloss.ThickBorder(), true, false) // top+bottom only
lipgloss.NewStyle().Border(lipgloss.DoubleBorder(), true, false, false, true) // top+left
```

## Color System

### Color Profiles
```go
// ANSI 16 (4-bit)
lipgloss.Color("5")     // magenta
lipgloss.Color("9")     // red

// ANSI 256 (8-bit)
lipgloss.Color("86")    // aqua
lipgloss.Color("201")   // hot pink

// True Color (24-bit)
lipgloss.Color("#0000FF")
lipgloss.Color("#04B575")
```

### Named Constants (ANSI 16)
```go
lipgloss.Black, lipgloss.Red, lipgloss.Green, lipgloss.Yellow,
lipgloss.Blue, lipgloss.Magenta, lipgloss.Cyan, lipgloss.White,
lipgloss.BrightBlack, lipgloss.BrightRed, lipgloss.BrightGreen,
lipgloss.BrightYellow, lipgloss.BrightBlue, lipgloss.BrightMagenta,
lipgloss.BrightCyan, lipgloss.BrightWhite
```

### Color Utilities (NEW in v2)
```go
dark := lipgloss.Darken(color, 0.5)
light := lipgloss.Lighten(color, 0.35)
complement := lipgloss.Complementary(color)
withAlpha := lipgloss.Alpha(color, 0.2)
```

### Color Blending (NEW in v2)
```go
// 1D gradient (e.g. for progress bars)
colors := lipgloss.Blend1D(10, lipgloss.Color("#FF0000"), lipgloss.Color("#0000FF"))

// 2D gradient with rotation (e.g. for backgrounds)
colors := lipgloss.Blend2D(80, 24, 45.0, color1, color2, color3)
```

### Adaptive Colors (Light/Dark terminals)
```go
hasDarkBG := lipgloss.HasDarkBackground(os.Stdin, os.Stdout)
lightDark := lipgloss.LightDark(hasDarkBG)
myColor := lightDark(lipgloss.Color("#D7FFAE"), lipgloss.Color("#D75FEE"))
```

### Complete Colors (per-profile)
```go
import "github.com/charmbracelet/colorprofile"
profile := colorprofile.Detect(os.Stdout, os.Environ())
completeColor := lipgloss.Complete(profile)
myColor := completeColor(ansiColor, ansi256Color, trueColor)
```

### Auto Downsampling
```go
// Drop-in replacement for fmt that auto-downsample colors
lipgloss.Println(styledText)
lipgloss.Printf("Hello %s", styledText)
lipgloss.Fprint(os.Stderr, styledText)
lipgloss.Sprint(styledText) // to variable
// Full set: Print, Println, Printf, Fprint, Fprintln, Fprintf, Sprint, Sprintln, Sprintf
```

## Layout Utilities

### Joining
```go
// Horizontal (align shorter blocks by position)
lipgloss.JoinHorizontal(lipgloss.Bottom, a, b, c)
lipgloss.JoinHorizontal(lipgloss.Top, a, b)
lipgloss.JoinHorizontal(lipgloss.Center, a, b)
lipgloss.JoinHorizontal(0.2, a, b) // 20% from top

// Vertical (align narrower blocks by position)
lipgloss.JoinVertical(lipgloss.Center, a, b)
lipgloss.JoinVertical(lipgloss.Left, a, b)
lipgloss.JoinVertical(lipgloss.Right, a, b)
```

### Placement
```go
// Center in 80-wide space
lipgloss.PlaceHorizontal(80, lipgloss.Center, paragraph)

// Place at bottom of 30-tall space
lipgloss.PlaceVertical(30, lipgloss.Bottom, paragraph)

// Place in corner of 30x80 space
lipgloss.Place(30, 80, lipgloss.Right, lipgloss.Bottom, paragraph)
```

### Compositing (NEW in v2)
```go
a := lipgloss.NewLayer(pickles).X(4).Y(2).Z(1)
b := lipgloss.NewLayer(bitterMelon).X(22).Y(1)
c := lipgloss.NewLayer(sriracha).X(11).Y(7)
output := compositor.Compose(a, b, c).Render()
```

### Measurement
```go
w := lipgloss.Width(block)
h := lipgloss.Height(block)
w, h := lipgloss.Size(block)
```

### Wrapping
```go
wrapped := lipgloss.Wrap(styledText, 40, " ")
```

## Style Copying and Inheritance

```go
// Copying: assignment creates true copies (value type)
style := lipgloss.NewStyle().Foreground(lipgloss.Color("219"))
copy := style             // true independent copy
variant := style.Blink(true) // also a copy, with blink added

// Inheritance: only unset rules inherited
styleA := lipgloss.NewStyle().Foreground(lipgloss.Color("229")).Background(lipgloss.Color("63"))
styleB := lipgloss.NewStyle().Foreground(lipgloss.Color("201")).Inherit(styleA)
// styleB gets Background from styleA but keeps its own Foreground

// Unsetting
style.Bold(true).UnsetBold().Background(lipgloss.Color("227")).UnsetBackground()
```

## Table Sub-package

```go
import "charm.land/lipgloss/v2/table"

t := table.New().
    Border(lipgloss.NormalBorder()).
    BorderStyle(lipgloss.NewStyle().Foreground(purple)).
    Headers("LANGUAGE", "FORMAL", "INFORMAL").
    Rows(rows...).
    Row("English", "Hello", "Hey").
    StyleFunc(func(row, col int) lipgloss.Style {
        switch {
        case row == table.HeaderRow:
            return headerStyle
        case row%2 == 0:
            return evenRowStyle
        default:
            return oddRowStyle
        }
    })
lipgloss.Println(t)

// Markdown table
table.New().Border(lipgloss.MarkdownBorder()).BorderTop(false).BorderBottom(false)

// ASCII table
table.New().Border(lipgloss.ASCIIBorder())
```

## List Sub-package

```go
import "charm.land/lipgloss/v2/list"

l := list.New("A", "B", "C")
// Nested
l := list.New("A", list.New("A1", "A2"), "B", list.New("B1"))
// Styled
l.Enumerator(list.Roman).EnumeratorStyle(enumeratorStyle).ItemStyle(itemStyle)
// Custom enumerator
l.Enumerator(func(items list.Items, i int) string { return ">>>" })
// Incremental
l := list.New(); l.Item("A"); l.Item("B")
```

Predefined enumerators: `Arabic`, `Alphabet`, `Roman`, `Bullet`, `Tree`

## Tree Sub-package

```go
import "charm.land/lipgloss/v2/tree"

t := tree.Root(".").Child("A", "B", "C")
// Nested
t := tree.Root(".").Child("macOS").Child(
    tree.New().Root("Linux").Child("NixOS", "Arch", "Void"),
).Child(
    tree.New().Root("BSD").Child("FreeBSD", "OpenBSD"),
)
// Styled
t.Enumerator(tree.RoundedEnumerator).EnumeratorStyle(s).RootStyle(r).ItemStyle(i)
// Incremental
t := tree.New(); t.Child("A"); t.Child("B")
```

Predefined enumerators: `DefaultEnumerator` (sharp), `RoundedEnumerator` (rounded)
