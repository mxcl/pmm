# mxcl README Style

Use this reference when generating or rewriting a README in the pkgxdev/tea style.

## Essence

- Product docs, not marketing pages.
- A README should demonstrate the tool working before it exhaustively explains it.
- A README is an overview and a path to success, not the complete manual.
- The voice is confident, practical, lightly opinionated, and occasionally wry.
- The best paragraphs feel written by the maintainer who knows the sharp edges.
- The user is a developer. Respect their time and show them commands.

## Opening Pattern

Prefer one of these openings:

- Banner or logo image, then a single-line product definition.
- H1 with backticked CLI name, then a single-line product definition.
- H1 product name, then a tiny tagline for GUI/product repos.

Then move fast:

- Optional badge row.
- Optional admonition with the product worldview or main caveat.
- `## Quickstart`, `## Getting Started`, or the primary task.

Avoid:

- Long origin stories.
- "Welcome to..." phrasing.
- Generic feature lists before the first command.
- Exhaustive command references.
- Tables of every flag, option, environment variable, input, output, or config key.
- Explaining what open source, CLIs, GitHub Actions, shells, or package managers are.

## Scope: The 80% Path

The README should give a potential user a good overview and enough confidence
to try the project. It should not explain everything.

Document:

- the common install path
- the first useful command
- one representative workflow that proves the product promise
- the most important caveats
- where to go next

Do not document:

- every command
- every flag
- every config field
- every input/output
- every platform-specific edge case
- every troubleshooting branch

For the remainder, link to the canonical documentation if it exists:

```markdown
> [docs.example.com]
```

If there is no online documentation, point to the built-in help:

````markdown
For the rest:

```sh
$ tool --help
```
````

For CLIs with subcommands, prefer the shortest accurate pointer: `tool --help`,
`tool help`, or `tool help <subcommand>`. For GitHub Actions, point to
`action.yml` for the full input/output surface.

## Voice

Write like this:

- Short sentences. Occasional sentence fragments are fine.
- Use contractions naturally.
- Use direct recommendations: "Use X", "No.", "Your call."
- Use first person plural for maintainer choices: "We provide...", "We support...", "We store...".
- Use second person for user impact: "you get...", "you can...", "you probably want...".
- Admit uncertainty and novelty: "new software", "experimental", "limited", "edge cases".
- Include dry asides sparingly when they clarify a tradeoff.

Do not write like this:

- "Seamlessly empowers developers to leverage..."
- "Robust and scalable solution..."
- "Simply just..."
- "This comprehensive guide will..."
- Overly polished enterprise copy.

## Structure Patterns

### CLI Tool

1. `# \`tool\`` or banner plus one-sentence definition.
2. Note/caution if install location, beta status, or isolation matters.
3. Quickstart or usage command block.
4. Main promise as an H1 or H2 with a transcript.
5. One short usage section covering the common path.
6. A "for the rest" pointer to online docs or `tool --help`.
7. Caveats and contributing.

### GitHub Action

1. Banner or concise bullets saying what the repo provides.
2. `# GitHub Action`.
3. Minimal `uses:` example.
4. Inputs/outputs through realistic YAML.
5. A pointer to `action.yml` for the full input/output surface.
6. Cache/platform/version guidance.
7. Installer or secondary repo responsibility, if applicable.

### macOS/Product App

1. Product name and terse tagline.
2. Download badge if available.
3. Warning if beta or platform-limited.
4. Feature sections with screenshots.
5. Short explanation of why the feature exists.
6. Security/data-loss caveats in admonitions.
7. Contributing/debugging notes with practical quirks.

## Formatting Idioms

- Use fenced shell transcripts:

```sh
$ command
output
# ^^ explanation of the preceding line
```

- Use admonitions for important context:

```markdown
> [!NOTE]
> Packages are installed somewhere specific and not exposed globally.
```

- Use `<details><summary>Label</summary><br>` for optional platform, Docker, CI, editor, or advanced usage sections.
- Prefer long-form flags the first time a command appears: `--global` instead of `-g`, `--yes` instead of `-y`, `--help` instead of `-h`, `--version` instead of `-v`, when the command supports them.
- Short flags are fine in later examples or dense transcripts once the long form has appeared.
- Use `&nbsp;` as an intentional visual spacer only when the README otherwise becomes dense.
- Use inline code for commands, paths, files, package names, versions, and config keys.
- Use italics for emphasis, not decoration.
- Use bullets for terse facts and numbered lists for procedures.
- Use reference-style links when the same destination appears more than once.

## Heading Style

- Headings should be claims or user questions, not vague categories.
- Good: `# Run Anything`, `## Run Anywhere`, `## Should you Cache ~/.pkgx?`, `## Temporary Sandboxes`.
- Acceptable: `## Usage`, `## Installation`, `## Contributing`.
- Weak: `## Features`, `## Overview`, `## Benefits` unless the content is unusually concrete.

## Example Blocks

Examples should usually show a before/after or concrete workflow:

```sh
$ tool-that-is-missing
command not found: tool-that-is-missing

$ your-tool tool-that-is-missing
useful output

$ tool-that-is-missing
command not found: tool-that-is-missing
# ^^ nothing was installed globally
```

Prefer comments inside the block when a note belongs to the command. Prefer prose outside the block when it explains a decision.

## Caveats

Make caveats crisp:

- "No." can be a complete answer when followed by the reason.
- "You should probably..." is acceptable when there are valid exceptions.
- "If you don't trust us..." is acceptable for security-sensitive shell modifications, but only when paired with a dry-run or inspection command.
- "This is new software" belongs near risky operations.

Do not hide caveats at the end if they affect install, security, data loss, or platform support.

## Content Checklist

Before returning a README, verify:

- The first screen tells a developer what the thing does.
- The first command appears early.
- Commands are plausible for the repo and ecosystem.
- The main example proves the core promise.
- First-use flags prefer long form when available.
- Only the 80% path is documented.
- Full command/input/config coverage is delegated to online docs, `--help`, or `action.yml`.
- Warnings are specific, not defensive.
- There is no filler marketing copy.
- Links resolve or match existing repo conventions.
- Screenshots/images are reused from the repo or documented as placeholders.
