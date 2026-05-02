# Enman

A minimalistic environment manager for Git Worktree workflows.

## Goal

Provide a lightweight way to spin up and manage per-worktree shell environments so each branch can have isolated tooling, variables, and startup behavior without heavy setup.

## What this project aims to do

- Keep worktree setup simple and fast.
- Reduce context switching between branches.
- Standardize environment bootstrapping for local development.
- Stay script-first and easy to customize.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/ibedwi/enman/main/install.sh | bash
```

Then reload your shell:

```bash
source ~/.zshrc   # or source ~/.bashrc
```

This clones enman to `~/.enman/bin/` and adds an `enman` alias to your shell config.

## Quick Start

1. Prepare your project env templates under:

```text
~/.enman/projects/<project-name>/environments/<env>/...
```

All project data is stored in `~/.enman/` in your home directory. You can override this by setting the `ENMAN_HOME` environment variable. Each project holds one or more environments (e.g. `development`, `staging`, `production`).

2. Scan your project to capture env files:

```bash
enman scan <project-name> [directory] [--env <env>] [--include <pattern>]...

# Scan for .env files into the default 'development' environment
enman scan my-app

# Scan into a specific environment
enman scan my-app --env staging

# Scan for all .env variants
enman scan my-app --include ".env*"

# Scan for multiple patterns
enman scan my-app --include ".env*" --include "config.yaml"

# Scan a specific directory into staging
enman scan my-app /path/to/monorepo --env staging --include ".env*"
```

The `--env` flag selects which environment to scan into (defaults to `development`). The `--include` flag specifies file patterns to scan for (can be repeated). Defaults to `.env` if not specified. A `.enman` manifest file is written to the env directory listing the patterns used and all included files.

3. Copy files into a target worktree directory:

```bash
enman setup <project-name> <target-directory> [--env <env>]
# example (uses 'development' by default)
enman setup my-cool-project /path/to/worktree
# example (specific env)
enman setup my-cool-project /path/to/worktree --env staging
```

The command copies all files from `~/.enman/projects/<project-name>/environments/<env>/` to `<target-directory>`, preserving directory structure. Metadata files (`.archived`, `.enman`) are excluded.

## CLI Commands

- `enman setup <project-name> <target-directory> [--env <env>]`
- `enman scan <project-name> [directory] [--env <env>] [--include <pattern>]...`
- `enman projects <action> [arguments]`
- `enman environments <action> <project-name> [env-name]`
- `enman update`
