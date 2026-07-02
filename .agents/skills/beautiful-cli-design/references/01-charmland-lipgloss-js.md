# @charmland/lipgloss -- Official JS Port of Lip Gloss

**Package**: `@charmland/lipgloss` (npm)
**Version**: 2.0.0-beta.3 (experimental)
**License**: MIT
**Size**: 1.12 MB (includes native bindings)
**Status**: Experimental beta -- not all Go features ported yet

## Installation

```bash
npm i @charmland/lipgloss
```

## Core Exports

```javascript
const {
  Style,
  Color,
  NoColor,
  LightDark,
  Table,
  TableData,
  List,
  Tree,
  Leaf,
  Bullet,
  RoundedEnumerator,
  JoinHorizontal,
  JoinVertical,
  Place,
  Center, Right, Bottom, Top, Left,
  NormalBorder,
  RoundedBorder,
  BlockBorder,
  OuterHalfBlockBorder,
  InnerHalfBlockBorder,
  ThickBorder,
  DoubleBorder,
  HiddenBorder,
  MarkdownBorder,
  ASCIIBorder,
  Width,
  Height,
  Size,
} = require("@charmland/lipgloss");
```

## Style API (97.62% ported)

Style objects are created with `new Style()` and methods are chainable.

```javascript
const s = new Style()
  .foreground(Color("#FAFAFA"))
  .background(Color("#7D56F4"))
  .bold(true)
  .italic(true)
  .faint(true)
  .underline(true)
  .strikethrough(true)
  .strikethroughSpaces(true)
  .underlineSpaces(true)
  .reverse(true)
  .width(22)
  .height(5)
  .maxWidth(40)
  .maxHeight(10)
  .padding(2, 4)          // top/bottom, left/right
  .paddingTop(2)
  .paddingBottom(2)
  .paddingLeft(4)
  .paddingRight(4)
  .margin(1, 2)
  .marginTop(1)
  .marginBottom(1)
  .marginLeft(2)
  .marginRight(2)
  .marginBackground(Color("#333"))
  .align(Center)           // Center, Left, Right
  .alignHorizontal(Center)
  .alignVertical(Center)
  .colorWhitespace(true)
  .tabWidth(4)
  .inline(true)
  .border(NormalBorder())
  .borderStyle(RoundedBorder())
  .setBorderTop(true)
  .setBorderBottom(true)
  .setBorderLeft(true)
  .setBorderRight(true)
  .borderForeground(Color("63"))
  .borderTopForeground(Color("63"))
  .borderRightForeground(Color("63"))
  .borderBottomForeground(Color("63"))
  .borderLeftForeground(Color("63"))
  .borderBackground(Color("0"))
  .borderTopBackground(Color("0"))
  .borderRightBackground(Color("0"))
  .borderBottomBackground(Color("0"))
  .borderLeftBackground(Color("0"))
  .setString("Hello")
  .inherit(otherStyle);

// Render
const output = s.render("Hello, world");
console.log(output);

// Or use .render as a function reference
const render = s.render;
console.log(render("text"));
```

### NOT yet ported
- `Transform` (style method)
- `EnableLegacyWindowsANSI`

## Color System (100% ported)

```javascript
// ANSI 16 colors (4-bit)
Color("5")     // magenta
Color("9")     // red

// ANSI 256 colors (8-bit)
Color("86")    // aqua
Color("201")   // hot pink

// True Color (24-bit)
Color("#0000FF")  // blue
Color("#04B575")  // green

// No color (transparent)
NoColor()

// Light/Dark adaptive color
LightDark(lightColor, darkColor)

// Background detection
HasDarkBackground()  // returns boolean

// RGBA extraction
const [r, g, b, a] = Color("#FF0000").RGBA();
```

## Border Styles (100% ported)

All 10 border styles are available:

```javascript
NormalBorder()          // ─│┌┐└┘
RoundedBorder()         // ─│╭╮╰╯
ThickBorder()           // ━┃┏┓┗┛
DoubleBorder()          // ═║╔╗╚╝
HiddenBorder()          // (invisible, takes up space)
BlockBorder()           // █ characters
InnerHalfBlockBorder()  // ▄▐▗▖▀▌▝▘
OuterHalfBlockBorder()  // ▀▌▛▜▄▐▙▟
MarkdownBorder()        // | - for markdown-style tables
ASCIIBorder()           // + - | for maximum compatibility
```

## Table API (100% ported)

```javascript
// Simple table
const table = new Table()
  .headers("Name", "Age", "City")
  .row("Alice", "25", "NYC")
  .row("Bob", "30", "SF")
  .row("Charlie", "35", "LA")
  .border(NormalBorder())
  .borderStyle(new Style().foreground(Color("99")))
  .borderTop(true)
  .borderBottom(true)
  .borderLeft(true)
  .borderRight(true)
  .borderHeader(true)
  .borderColumn(true)
  .borderRow(false)
  .width(60)
  .height(10)
  .offset(0)
  .wrap(false)
  .styleFunc((row, col) => {
    if (row === -1) {
      // Header row
      return new Style().foreground(Color("99")).bold(true);
    }
    if (row % 2 === 0) {
      return new Style().foreground(Color("245")).padding(0, 1);
    }
    return new Style().foreground(Color("241")).padding(0, 1);
  })
  .render();

console.log(table);
```

### TableData API

```javascript
// Create with initial data
const data = new TableData(
  ["Name", "Age", "City"],      // first row becomes headers
  ["Alice", "25", "NYC"],
  ["Bob", "30", "SF"]
);

// Or build incrementally
const data2 = new TableData()
  .append(["Product", "Price"])
  .append(["Laptop", "$999"])
  .append(["Mouse", "$25"]);

// Or add multiple rows at once
data2.rows(
  ["Keyboard", "$149"],
  ["Monitor", "$499"]
);

// Access data
data.at(0, 1);        // "25" (row 0, col 1)
data.rowCount();       // 2
data.columnCount();    // 3

// Use with Table
new Table().data(data).render();
```

## List API (100% ported)

```javascript
// Simple list
const list = new List("Bananas", "Barley", "Cashews", "Milk")
  .enumerator(Bullet)
  .itemStyle(new Style().foreground(Color("255")))
  .enumeratorStyle(new Style().foreground(Color("99")).marginRight(1))
  .render();

console.log(list);
// Outputs:
// * Bananas
// * Barley
// * Cashews
// * Milk

// List methods
list.item("New Item");       // add item
list.items("A", "B", "C");  // add multiple
list.hide(true);             // hide the list
list.offset(2);              // skip first 2 items
list.indenter(customFn);     // custom indentation
list.itemStyleFunc((items, i) => { ... });
list.enumeratorStyleFunc((items, i) => { ... });
```

## Tree API (95% ported)

```javascript
const tree = new Tree()
  .root("Makeup")
  .child(
    "Glossier",
    "Fenty Beauty",
    new Tree().child(
      new Leaf("Gloss Bomb"),
      new Leaf("Hot Cheeks")
    ),
    new Leaf("Nyx"),
    "Mac"
  )
  .enumerator(RoundedEnumerator)
  .enumeratorStyle(new Style().foreground(Color("63")).marginRight(1))
  .rootStyle(new Style().foreground(Color("35")))
  .itemStyle(new Style().foreground(Color("212")))
  .render();

// Outputs:
// Makeup
// ├── Glossier
// ├── Fenty Beauty
// │   ├── Gloss Bomb
// │   └── Hot Cheeks
// ├── Nyx
// └── Mac

// Leaf API
const leaf = new Leaf("value");
leaf.value();         // "value"
leaf.setValue("new");
leaf.hidden();        // false
leaf.setHidden(true);
leaf.string();        // string representation

// NOT yet ported: custom enumerators, custom indenters
```

## Layout Utilities (100% ported)

```javascript
// Join horizontally (left-to-right)
JoinHorizontal(Center, blockA, blockB, blockC);
JoinHorizontal(Top, blockA, blockB);
JoinHorizontal(Bottom, blockA, blockB);

// Join vertically (top-to-bottom)
JoinVertical(Center, blockA, blockB);
JoinVertical(Left, blockA, blockB);
JoinVertical(Right, blockA, blockB);

// Place text in whitespace
Place(width, height, horizontalPos, verticalPos, text);
// Example: center text in a 80x24 block
Place(80, 24, Center, Center, "Hello!");

// Measure rendered text
Width("rendered text");   // character width
Height("rendered\ntext"); // line count
Size("rendered\ntext");   // [width, height]
```

## Environment Variables

```bash
LIPGLOSS_DEBUG=true    # Enable debug output
DEBUG=lipgloss         # Standard debug pattern
DEBUG=*                # All debug output
```

## NO_COLOR and Pipe Detection

The JS port respects the same environment signals as the Go version:
- `NO_COLOR` environment variable disables all color output
- Non-TTY output (pipes) should be detected by the application

## Compatibility Notes

- CommonJS only (`require()`) -- no ESM imports
- Native bindings (1.12 MB package size)
- Node.js only (no browser/Deno/Bun support confirmed)
- Beta quality: some edge cases in Unicode handling
- 0 npm dependents as of March 2026 (very new)
