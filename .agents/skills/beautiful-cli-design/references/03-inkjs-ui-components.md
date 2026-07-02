# @inkjs/ui -- Pre-built Ink Components

**Package**: `@inkjs/ui` (npm)
**Version**: 2.0.0 (requires Ink 5, Node.js 18+)
**License**: MIT
**GitHub**: https://github.com/vadimdemedes/ink-ui
**Stars**: 2k | Used by 955+ packages

## Installation

```bash
npm install @inkjs/ui
# Requires ink and react already installed
```

## Components

### TextInput

Single-line text input with optional autocomplete.

```tsx
import { TextInput } from '@inkjs/ui';

<TextInput
  placeholder="Enter your name..."
  onSubmit={(name) => { /* name contains user input */ }}
/>

// With autocomplete suggestions
<TextInput
  placeholder="Search..."
  suggestions={["apple", "banana", "cherry"]}
  onSubmit={(value) => { ... }}
/>
```

### EmailInput

Email input with domain autocomplete after "@".

```tsx
import { EmailInput } from '@inkjs/ui';

<EmailInput
  placeholder="Enter email..."
  onSubmit={(email) => { /* email contains user input */ }}
/>
```

### PasswordInput

Masked input for sensitive data (shows asterisks).

```tsx
import { PasswordInput } from '@inkjs/ui';

<PasswordInput
  placeholder="Enter password..."
  onSubmit={(password) => { /* password contains user input */ }}
/>
```

### ConfirmInput

Y/n confirmation prompt.

```tsx
import { ConfirmInput } from '@inkjs/ui';

<ConfirmInput
  onConfirm={() => { /* user confirmed */ }}
  onCancel={() => { /* user cancelled */ }}
/>
```

### Select

Scrollable single-select list.

```tsx
import { Select } from '@inkjs/ui';

<Select
  options={[
    { label: 'Red', value: 'red' },
    { label: 'Green', value: 'green' },
    { label: 'Yellow', value: 'yellow' },
  ]}
  onChange={(newValue) => {
    // newValue equals the `value` field of the selected option
  }}
/>
```

### MultiSelect

Scrollable multi-select list.

```tsx
import { MultiSelect } from '@inkjs/ui';

<MultiSelect
  options={[
    { label: 'Red', value: 'red' },
    { label: 'Green', value: 'green' },
    { label: 'Yellow', value: 'yellow' },
  ]}
  onChange={(newValues) => {
    // newValues is an array of selected `value` fields
    // e.g. ["green", "yellow"]
  }}
/>
```

### Spinner

Loading indicator with label.

```tsx
import { Spinner } from '@inkjs/ui';

<Spinner label="Loading" />
```

### ProgressBar

Determinate progress indicator.

```tsx
import { ProgressBar } from '@inkjs/ui';

// value must be between 0 and 100
<ProgressBar value={64} />
```

### Badge

Status indicator badge.

```tsx
import { Badge } from '@inkjs/ui';

<Badge color="green">Pass</Badge>
<Badge color="red">Fail</Badge>
<Badge color="yellow">Warn</Badge>
<Badge color="blue">Todo</Badge>
```

### StatusMessage

Status with longer explanation text.

```tsx
import { StatusMessage } from '@inkjs/ui';

<StatusMessage variant="success">
  New version is deployed to production
</StatusMessage>
<StatusMessage variant="error">
  Failed to deploy a new version
</StatusMessage>
<StatusMessage variant="warning">
  Health checks aren't configured
</StatusMessage>
<StatusMessage variant="info">
  This version is already deployed
</StatusMessage>
```

**variant values:** `success`, `error`, `warning`, `info`

### Alert

Boxed alert for important messages.

```tsx
import { Alert } from '@inkjs/ui';

<Alert variant="success">
  A new version of this CLI is available
</Alert>
<Alert variant="error">
  Your license is expired
</Alert>
<Alert variant="warning">
  Current version has been deprecated
</Alert>
<Alert variant="info">
  API won't be available tomorrow
</Alert>
```

### UnorderedList

Nested bullet lists.

```tsx
import { UnorderedList } from '@inkjs/ui';

<UnorderedList>
  <UnorderedList.Item>
    <Text>Red</Text>
  </UnorderedList.Item>
  <UnorderedList.Item>
    <Text>Green</Text>
    <UnorderedList>
      <UnorderedList.Item><Text>Light</Text></UnorderedList.Item>
      <UnorderedList.Item><Text>Dark</Text></UnorderedList.Item>
    </UnorderedList>
  </UnorderedList.Item>
  <UnorderedList.Item>
    <Text>Blue</Text>
  </UnorderedList.Item>
</UnorderedList>
```

### OrderedList

Nested numbered lists.

```tsx
import { OrderedList } from '@inkjs/ui';

<OrderedList>
  <OrderedList.Item><Text>First</Text></OrderedList.Item>
  <OrderedList.Item>
    <Text>Second</Text>
    <OrderedList>
      <OrderedList.Item><Text>Sub A</Text></OrderedList.Item>
      <OrderedList.Item><Text>Sub B</Text></OrderedList.Item>
    </OrderedList>
  </OrderedList.Item>
</OrderedList>
```

## Theming System

All components read styles from a React context-based theme.

### Default Theme

```tsx
import { ThemeProvider, defaultTheme } from '@inkjs/ui';

<ThemeProvider theme={defaultTheme}>
  <App />
</ThemeProvider>
```

### Custom Theme via extendTheme

```tsx
import { render, type TextProps } from 'ink';
import { Spinner, ThemeProvider, extendTheme, defaultTheme } from '@inkjs/ui';

const customTheme = extendTheme(defaultTheme, {
  components: {
    Spinner: {
      styles: {
        container: () => ({ gap: 1 }),
        frame: (): TextProps => ({ color: 'magenta' }),
        label: (): TextProps => ({ bold: true }),
      },
    },
    StatusMessage: {
      styles: {
        icon: ({ variant }) => ({
          color: {
            success: 'green',
            error: 'red',
            warning: 'yellow',
            info: 'blue',
          }[variant],
        }),
      },
    },
    UnorderedList: {
      config: () => ({
        marker: '+',  // default is '---'
      }),
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={customTheme}>
      <Spinner label="Loading" />
    </ThemeProvider>
  );
}
```

### Component Theme Structure

Each component theme has:
- `styles`: Object of functions returning BoxProps or TextProps
- `config`: Function returning non-style configuration

Style functions receive component props and state, enabling conditional styling.

### Custom Components with Themes

```tsx
import { useComponentTheme, type ComponentTheme } from '@inkjs/ui';

const customLabelTheme = {
  styles: {
    label: (): TextProps => ({ color: 'green' }),
  },
} satisfies ComponentTheme;

function CustomLabel() {
  const { styles } = useComponentTheme<typeof customLabelTheme>('CustomLabel');
  return <Text {...styles.label()}>Hello world</Text>;
}
```

## Key Exports

```tsx
import {
  // Components
  TextInput,
  EmailInput,
  PasswordInput,
  ConfirmInput,
  Select,
  MultiSelect,
  Spinner,
  ProgressBar,
  Badge,
  StatusMessage,
  Alert,
  UnorderedList,
  OrderedList,

  // Theming
  ThemeProvider,
  defaultTheme,
  extendTheme,
  useComponentTheme,
} from '@inkjs/ui';
```
