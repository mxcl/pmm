# Charm Log -- Beautiful Structured Logging

**Package**: `github.com/charmbracelet/log` (Go)
**Stars**: 3.2k
**License**: MIT
**GitHub**: https://github.com/charmbracelet/log

## What It Does

Minimal, colorful structured logging for the terminal. Uses Lip Gloss for
styling. Supports leveled logging, structured key-value pairs, JSON/logfmt
output, slog handler integration, and customizable styles.

## Go API

```go
import "github.com/charmbracelet/log"

// Global logger (timestamps on, level = info)
log.Debug("won't print")     // below default level
log.Info("Hello World!")
log.Warn("careful", "temp", 350)
log.Error("failed", "err", err)
log.Fatal("boom")            // calls os.Exit(1)
log.Print("always prints")   // regardless of level

// Formatted variants
log.Debugf("temp: %d", 350)
log.Warnf("status: %s", "hot")
log.Errorf("count: %d", 0)

// With context
log.With("batch", 2, "oven", "A").Info("Baking")
```

### New Loggers

```go
logger := log.New(os.Stderr)
logger.Warn("chewy!", "butter", true)

// With full options
logger := log.NewWithOptions(os.Stderr, log.Options{
    ReportCaller:    true,
    ReportTimestamp: true,
    TimeFormat:      time.Kitchen,
    Prefix:          "Baking ",
    Level:           log.DebugLevel,
})
```

### Levels

```go
log.DebugLevel
log.InfoLevel   // default
log.WarnLevel
log.ErrorLevel
log.FatalLevel

log.SetLevel(log.DebugLevel)
```

### Formatters

```go
log.SetFormatter(log.TextFormatter)    // default, colorful
log.SetFormatter(log.JSONFormatter)    // JSON output
log.SetFormatter(log.LogfmtFormatter)  // logfmt output
```

Note: styling only affects TextFormatter. Auto-disabled when output is not a TTY.

### Custom Styles (via Lip Gloss)

```go
styles := log.DefaultStyles()
styles.Levels[log.ErrorLevel] = lipgloss.NewStyle().
    SetString("ERROR!!").
    Padding(0, 1, 0, 1).
    Background(lipgloss.Color("204")).
    Foreground(lipgloss.Color("0"))
styles.Keys["err"] = lipgloss.NewStyle().Foreground(lipgloss.Color("204"))
styles.Values["err"] = lipgloss.NewStyle().Bold(true)

logger := log.New(os.Stderr)
logger.SetStyles(styles)
```

### Sub-loggers

```go
logger := log.NewWithOptions(os.Stderr, log.Options{Prefix: "Baking "})
batch2 := logger.With("batch", 2, "chocolateChips", true)
batch2.Debug("Preparing batch 2...")
```

### slog Handler

```go
handler := log.New(os.Stderr)
logger := slog.New(handler)
logger.Error("meow?")
```

### Standard Log Adapter

```go
logger := log.NewWithOptions(os.Stderr, log.Options{Prefix: "http"})
stdlog := logger.StandardLog(log.StandardLogOptions{
    ForceLevel: log.ErrorLevel,
})
server := &http.Server{ErrorLog: stdlog}
```

### Helper Functions

```go
func startOven(degree int) {
    log.Helper()  // skip this frame in caller reporting
    log.Info("Starting oven", "degree", degree)
}
```

## JavaScript Equivalents

There is no JS port of charmbracelet/log. Here are the equivalents:

### consola (Recommended)

Most similar in spirit: colorful, leveled, structured.

```bash
npm install consola
```

```javascript
import { consola } from 'consola';

consola.info('Hello');
consola.success('Done');
consola.warn('Careful');
consola.error('Failed');
consola.debug('Detail');

// Scoped/tagged
const logger = consola.withTag('http');
logger.info('Request received');

// Structured (key-value)
consola.info({ message: 'Request', method: 'GET', path: '/api' });
```

### pino

Structured logging standard for Node.js. JSON-focused.

```javascript
import pino from 'pino';
const logger = pino({ level: 'debug' });
logger.info({ batch: 2, temp: 375 }, 'Baking started');
// Use pino-pretty for colorful terminal output
```

### winston

Enterprise-grade structured logging.

```javascript
import winston from 'winston';
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.colorize(),
    winston.format.simple()
  ),
  transports: [new winston.transports.Console()],
});
```

### Gum log (shell integration)

Call gum log from Node.js for quick styled logging:

```javascript
const { execSync } = require('child_process');
function gumLog(level, message, fields = {}) {
  const args = ['gum', 'log', '--structured', '--level', level, JSON.stringify(message)];
  for (const [k, v] of Object.entries(fields)) {
    args.push(k, String(v));
  }
  execSync(args.join(' '), { stdio: 'inherit' });
}

gumLog('info', 'Server started', { port: 3000 });
gumLog('error', 'Connection failed', { host: 'db.example.com' });
```

## Comparison

| Feature | charmbracelet/log | consola | pino |
|---------|------------------|---------|------|
| Colorful terminal | Yes (Lip Gloss) | Yes | Via pino-pretty |
| Structured k/v | Yes | Partial | Yes (JSON) |
| JSON output | Yes | Yes | Yes (default) |
| Logfmt output | Yes | No | No |
| Level filtering | Yes | Yes | Yes |
| Custom styles | Lip Gloss | Limited | No |
| slog compatible | Yes | No | No |
| TTY detection | Yes (auto) | Yes | Via pino-pretty |
| Sub-loggers | .With() | .withTag() | .child() |
| Caller reporting | Yes | No | Yes |
