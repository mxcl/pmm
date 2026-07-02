---
name: mxcl-readme
description: >-
  Generate, rewrite, or review README.md files in mxcl's pkgxdev/tea style:
  concise developer-tool docs with a sharp product promise, command-transcript
  examples, GitHub admonitions, pragmatic caveats, install/use sections, and dry
  human asides. Use when the user asks for a README in "my style", "mxcl
  style", "pkgx style", or references pkgxdev/pkgx, pkgxdev/dev, pkgxdev/pkgm,
  pkgxdev/setup, or teaxyz/teabase as examples.
---

# mxcl README

Create READMEs that feel like the pkgx/dev/pkgm/setup/teaBASE examples: terse, useful, example-led, and unafraid to state tradeoffs plainly.

## Workflow

1. Establish the product truth before writing.
   - Inspect the repo for manifests, CLIs, `action.yml`, install scripts, docs, screenshots, package metadata, and tests.
   - Run `--help`, examples, or obvious smoke commands when practical.
   - Do not invent capabilities, platforms, versions, performance claims, or compatibility.

2. Read [references/style.md](references/style.md) before drafting or revising substantial README content.

3. Start with the promise.
   - Prefer a banner or product image if the repo already has one.
   - Put a one-sentence explanation immediately after the title/banner.
   - Add badges only when they already exist or are clearly meaningful.

4. Make the README executable.
   - Lead quickly into install, quickstart, or the primary "do the thing" workflow.
   - Use shell transcripts with `$` prompts, real output, and `# ^^` comments for explanations.
   - Prefer long-form flags the first time a command is shown: use `--global` before `-g`, `--yes` before `-y`, `--help` before `-h`, etc. Short forms are fine later once the meaning is established.
   - Prefer examples over prose. Add prose only when it changes a user's decision.
   - Document the 80% path only: the common install, first useful run, and one or two representative workflows.
   - Do not fully document every command, flag, config key, subcommand, input, output, or edge case.
   - For the rest, point users to the canonical online docs if the repo has them; otherwise point to `cmd --help`, `cmd help`, or the nearest existing help command.

5. Structure by user questions.
   - "How do I start?"
   - "What does this run/install/configure?"
   - "Where does it work?"
   - "What are the caveats?"
   - "How does it fit with the ecosystem?"
   - "How do I contribute/debug?"

6. Keep caveats visible and honest.
   - Use GitHub admonitions: `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`.
   - State beta/new/experimental status directly.
   - Explain security, platform, cache, or installation tradeoffs without corporate hedging.

7. Finish with a self-review pass.
   - Cut generic marketing adjectives.
   - Replace abstract claims with commands or concrete examples.
   - Cut manual-like sections that enumerate every option; keep only the overview and common path.
   - Expand first-use short flags to their long-form equivalents when available.
   - Check every command, link, file path, version, and platform claim.
   - Ensure the README can be skimmed: strong headings, short paragraphs, fenced examples, and reference links.

## Common Skeleton

Use this as a starting point, then delete sections that do not apply:

````markdown
# `name`

One sentence that says what it is and why it exists.

> [!NOTE]
> One useful truth, caveat or worldview statement.

## Quickstart

```sh
$ install-or-run command
$ first useful command
real output
# ^^ short explanation
```

# Primary Promise

```sh
$ before
failure or friction

$ tool fixes-it
useful output
```

## Installation

## Usage

For everything else:

> [docs.example.com] or `name --help`

## How It Works

## Caveats

## Contributing
````

## Output Rules

- Preserve the user's requested README filename and repo conventions.
- Use ASCII unless the target README already uses typographic punctuation or the exact product name requires it.
- Use fenced code blocks with language tags where obvious.
- Prefer reference-style links near the bottom for repeated or long URLs.
- Do not add a separate changelog, install guide, or docs tree unless the user asks.
- Do not turn the README into full command documentation. It should help a potential user understand the project and succeed at the common path, then send them to full docs or `--help`.
