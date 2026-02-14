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
~/.enman/projects/<project-name>/...
```

All project data is stored in `~/.enman/` in your home directory. You can override this by setting the `ENMAN_HOME` environment variable.

2. Copy env files into a target worktree directory:

```bash
enman setup <project-name> <target-directory>
# example
enman setup my-cool-project /path/to/worktree
```

The command copies all `.env` files from `~/.enman/projects/<project-name>` to `<target-directory>`, preserving directory structure.

## CLI Commands

- `enman setup <project-name> <target-directory>`
- `enman scan <project-name> [directory]`
- `enman projects <action> [arguments]`
