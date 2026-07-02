# Ink -- React for CLIs

**Package**: `ink` (npm)
**Current Version**: 5.x (requires Node.js 18+)
**License**: MIT
**GitHub**: https://github.com/vadimdemedes/ink
**Used by**: Claude Code (Anthropic), Gemini CLI (Google), Cloudflare Wrangler, Gatsby, Prisma, Linear, tap, Terraform CDK, and 3000+ packages

## Installation

```bash
npm install ink react
```

Scaffolding:
```bash
npx create-ink-app my-cli
```

## Architecture

Ink is a React renderer targeting the terminal. It uses Facebook's Yoga engine for Flexbox layout.
Every element is a flex container (like `div { display: flex }` in CSS). React's full feature
set works: hooks, context, suspense, error boundaries, refs, etc.

## Core Components

### `<Text>`

Displays styled text. Only text nodes and nested `<Text>` components allowed inside.

```tsx
import { Text } from 'ink';

<Text color="green" bold>Success!</Text>
<Text color="#005cc5" italic>Custom color</Text>
<Text backgroundColor="red" inverse>Alert</Text>
<Text dimColor>Muted text</Text>
<Text strikethrough underline>Decorated</Text>
<Text wrap="truncate-end">Very long text that gets truncated...</Text>
```

**Props:**
| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `color` | string | - | Foreground: "green", "#005cc5", "rgb(232,131,136)" |
| `backgroundColor` | string | - | Background color |
| `dimColor` | boolean | false | Reduced brightness |
| `bold` | boolean | false | Bold weight |
| `italic` | boolean | false | Italic style |
| `underline` | boolean | false | Underline |
| `strikethrough` | boolean | false | Strikethrough |
| `inverse` | boolean | false | Swap fg/bg |
| `wrap` | string | "wrap" | "wrap", "truncate", "truncate-start", "truncate-middle", "truncate-end" |

### `<Box>`

Flexbox container. The primary layout primitive.

```tsx
import { Box, Text } from 'ink';

// Horizontal layout (default)
<Box gap={1}>
  <Text>Left</Text>
  <Text>Right</Text>
</Box>

// Vertical layout
<Box flexDirection="column" padding={1}>
  <Text>Top</Text>
  <Text>Bottom</Text>
</Box>

// Centered with border
<Box
  borderStyle="round"
  borderColor="blue"
  padding={1}
  width={40}
  justifyContent="center"
  alignItems="center"
>
  <Text>Centered content</Text>
</Box>

// Full-width with flex
<Box width="100%">
  <Box flexGrow={1}><Text>Fills space</Text></Box>
  <Box width={20}><Text>Fixed width</Text></Box>
</Box>
```

**Dimension Props:**
| Prop | Type | Default |
|------|------|---------|
| `width` | number/string | - |
| `height` | number/string | - |
| `minWidth` | number | - |
| `minHeight` | number/string | - |
| `maxWidth` | number | - |
| `maxHeight` | number/string | - |
| `aspectRatio` | number | - |

**Padding Props:**
| Prop | Type | Default |
|------|------|---------|
| `padding` | number | 0 |
| `paddingX` | number | 0 |
| `paddingY` | number | 0 |
| `paddingTop` | number | 0 |
| `paddingBottom` | number | 0 |
| `paddingLeft` | number | 0 |
| `paddingRight` | number | 0 |

**Margin Props:** Same pattern as padding.

**Gap Props:**
| Prop | Type | Default |
|------|------|---------|
| `gap` | number | 0 |
| `columnGap` | number | 0 |
| `rowGap` | number | 0 |

**Flex Props:**
| Prop | Type | Default |
|------|------|---------|
| `flexGrow` | number | 0 |
| `flexShrink` | number | 1 |
| `flexBasis` | number/string | - |
| `flexDirection` | string | "row" |
| `flexWrap` | string | "nowrap" |
| `alignItems` | string | "stretch" |
| `alignSelf` | string | "auto" |
| `alignContent` | string | "flex-start" |
| `justifyContent` | string | "flex-start" |

**flexDirection values:** `row`, `row-reverse`, `column`, `column-reverse`
**alignItems values:** `flex-start`, `center`, `flex-end`, `stretch`, `baseline`
**justifyContent values:** `flex-start`, `center`, `flex-end`, `space-between`, `space-around`, `space-evenly`

**Position Props:**
| Prop | Type | Default |
|------|------|---------|
| `position` | string | "relative" |
| `top` | number/string | - |
| `right` | number/string | - |
| `bottom` | number/string | - |
| `left` | number/string | - |

**Display Props:**
| Prop | Type | Default |
|------|------|---------|
| `display` | string | "flex" |
| `overflow` | string | "visible" |
| `overflowX` | string | "visible" |
| `overflowY` | string | "visible" |

**Border Props:**
| Prop | Type | Default |
|------|------|---------|
| `borderStyle` | string/object | - |
| `borderColor` | string | - |
| `borderTopColor` | string | - |
| `borderRightColor` | string | - |
| `borderBottomColor` | string | - |
| `borderLeftColor` | string | - |
| `borderDimColor` | boolean | false |
| `borderTop` | boolean | true |
| `borderRight` | boolean | true |
| `borderBottom` | boolean | true |
| `borderLeft` | boolean | true |

**borderStyle values:** `single`, `double`, `round`, `bold`, `singleDouble`, `doubleSingle`, `classic`

**Custom border object:**
```tsx
<Box borderStyle={{
  topLeft: '╔', top: '═', topRight: '╗',
  left: '║', right: '║',
  bottomLeft: '╚', bottom: '═', bottomRight: '╝'
}}>
  <Text>Custom border</Text>
</Box>
```

### `<Newline>`

```tsx
<Text>Line one<Newline count={2} />Line three</Text>
```

### `<Spacer>`

Expands to fill available space along the major axis.

```tsx
<Box>
  <Text>Left</Text>
  <Spacer />
  <Text>Right</Text>
</Box>
```

### `<Static>`

Renders items permanently above the dynamic output. Items are rendered once and never re-rendered.

```tsx
const [logs, setLogs] = useState([]);

<Static items={logs}>
  {(log, index) => (
    <Text key={index} color="gray">[{log.time}] {log.message}</Text>
  )}
</Static>
<Box>
  <Text>Current status: running...</Text>
</Box>
```

### `<Transform>`

Transforms each line of string output before rendering.

```tsx
<Transform transform={(output, index) => `${index}: ${output}`}>
  <Text>First line</Text>
  <Text>Second line</Text>
</Transform>
// Output:
// 0: First line
// 1: Second line
```

## Hooks

### `useInput(handler, options?)`

```tsx
import { useInput } from 'ink';

useInput((input, key) => {
  if (key.return) {
    // Enter pressed
  }
  if (key.escape) {
    // Escape pressed
  }
  if (key.upArrow) {
    // Up arrow pressed
  }
  if (input === 'q') {
    // q pressed
  }
  if (key.ctrl && input === 'c') {
    // Ctrl+C pressed
  }
}, { isActive: true });
```

**key object properties:**
- Arrow keys: `leftArrow`, `rightArrow`, `upArrow`, `downArrow`
- Special: `return`, `escape`, `tab`, `backspace`, `delete`
- Navigation: `pageUp`, `pageDown`, `home`, `end`
- Modifiers: `ctrl`, `shift`, `meta`, `super`, `hyper`
- State: `capsLock`, `numLock`
- `eventType`: `'press'`, `'repeat'`, `'release'` (kitty keyboard)

### `useApp()`

```tsx
import { useApp } from 'ink';

const { exit } = useApp();
exit();           // clean exit
exit(error);      // exit with error
exit(result);     // exit with result value
```

### `useStdin()` / `useStdout()` / `useStderr()`

```tsx
const { stdin, isRawModeSupported, setRawMode } = useStdin();
const { stdout, write } = useStdout();
const { stderr, write: writeErr } = useStderr();
```

### `useWindowSize()`

```tsx
const { columns, rows } = useWindowSize();
// Updates on terminal resize
```

### `useFocus(options?)` / `useFocusManager()`

```tsx
// In a focusable component
const { isFocused } = useFocus({ autoFocus: true, id: 'input-1' });

// In a parent managing focus
const { focusNext, focusPrevious, focus, activeId } = useFocusManager();
focus('input-1');  // focus by ID
```

### `usePaste(handler)`

```tsx
usePaste((text) => {
  // Receives pasted text including newlines
  // Bracketed paste mode enabled automatically
});
```

### `useBoxMetrics(ref)`

```tsx
const ref = useRef();
const { width, height, left, top, hasMeasured } = useBoxMetrics(ref);
<Box ref={ref}>...</Box>
```

### `useCursor()`

```tsx
const { setCursorPosition } = useCursor();
setCursorPosition({ x: 5, y: 3 }); // position cursor
setCursorPosition(undefined);        // hide cursor
```

## render() API

```tsx
import { render } from 'ink';

const instance = render(<App />, {
  stdout: process.stdout,
  stdin: process.stdin,
  stderr: process.stderr,
  exitOnCtrlC: true,
  patchConsole: true,
  maxFps: 30,
  debug: false,
  incrementalRendering: false,
  concurrent: false,
  alternateScreen: false,    // full-screen mode
  interactive: undefined,     // auto-detected from TTY
  isScreenReaderEnabled: false,
  kittyKeyboard: undefined,
});

instance.rerender(<App updated />);
instance.unmount();
await instance.waitUntilExit();
instance.clear();
instance.cleanup();

// String rendering (for testing)
import { renderToString } from 'ink';
const output = renderToString(<App />, { columns: 80 });
```

## Full-Screen App Pattern

```tsx
import { render, Box, Text, useInput, useApp } from 'ink';

function App() {
  const { exit } = useApp();

  useInput((input, key) => {
    if (input === 'q' || key.escape) {
      exit();
    }
  });

  return (
    <Box flexDirection="column" width="100%" height="100%">
      <Box borderStyle="single" borderColor="blue" paddingX={1}>
        <Text bold>My App</Text>
        <Spacer />
        <Text dimColor>Press q to quit</Text>
      </Box>
      <Box flexGrow={1} padding={1}>
        <Text>Main content area</Text>
      </Box>
      <Box borderStyle="single" borderColor="gray" paddingX={1}>
        <Text>Status bar</Text>
      </Box>
    </Box>
  );
}

render(<App />, { alternateScreen: true });
```

## CI Behavior

Ink detects CI environments (via `CI` env var) and adapts: only the last frame
renders on exit instead of continuous updates. Override with `CI=false`.

## Screen Reader / Accessibility

```tsx
<Box aria-role="list" aria-label="Todo items">
  <Box aria-role="listitem" aria-state={{ checked: true }}>
    <Text>Buy milk</Text>
  </Box>
</Box>
```

Enable: `INK_SCREEN_READER=true` or `isScreenReaderEnabled` option.
