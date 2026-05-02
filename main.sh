#!/bin/bash

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if command is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Available commands:"
    echo "  init                                                                  - Add 'enman-demo' alias to shell config"
    echo "  setup <project-name> <target-directory> [--env <env>]                - Copy project files to target directory"
    echo "  scan <project-name> [directory] [--env <env>] [--include <pattern>]... - Scan directory for files and save to project"
    echo "  projects <action> [arguments]                                        - Manage projects (create, list, archive, delete)"
    echo "  environments <action> <project-name> [env-name]                      - Manage environments (list, create, delete)"
    echo "  export <project-name> [--env <env>] [--output <file>]                - Bundle a project (or env) as a tar.gz archive"
    echo "  import <file> [--project <name>] [--env <env>]                       - Restore a project (or env) from a bundle"
    echo "  update                                                               - Update enman to the latest version"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 setup my-cool-project /path/to/target"
    echo "  $0 setup my-cool-project /path/to/target --env staging"
    echo "  $0 scan my-app"
    echo "  $0 scan my-app /path/to/monorepo"
    echo "  $0 scan my-app --env staging"
    echo "  $0 scan my-app --include \".env*\""
    echo "  $0 scan my-app --include \".env*\" --include \"config.yaml\""
    echo "  $0 projects create my-app"
    echo "  $0 projects list"
    echo "  $0 environments list my-app"
    echo "  $0 environments create my-app qa"
    echo "  $0 export my-app"
    echo "  $0 export my-app --env production --output /tmp/prod.tar.gz"
    echo "  $0 import my-app-20260102-120000.tar.gz"
    echo "  $0 import bundle.tar.gz --project my-app-copy"
    exit 1
fi

COMMAND="$1"
shift  # Remove the first argument (command) so we can pass the rest

case "$COMMAND" in
    init)
        # Determine which shell config file to use
        SHELL_CONFIG=""
        if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "$(which zsh)" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "$(which bash)" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        else
            echo "Error: Could not detect shell type (bash or zsh)"
            exit 1
        fi

        ALIAS_LINE="alias enman-demo='$SCRIPT_DIR/main.sh'"

        # Check if alias already exists
        if grep -q "alias enman-demo=" "$SHELL_CONFIG" 2>/dev/null; then
            echo "Alias 'enman-demo' already exists in $SHELL_CONFIG"
            echo "Updating to point to: $SCRIPT_DIR/main.sh"
            # Remove old alias and add new one
            grep -v "alias enman-demo=" "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp"
            mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"
        fi

        # Add the alias
        echo "" >> "$SHELL_CONFIG"
        echo "# enman-demo alias" >> "$SHELL_CONFIG"
        echo "$ALIAS_LINE" >> "$SHELL_CONFIG"

        echo "✓ Alias 'enman-demo' added to $SHELL_CONFIG"
        echo ""
        echo "To use the alias, run:"
        echo "  source $SHELL_CONFIG"
        echo ""
        echo "Or restart your terminal session."
        echo ""
        echo "Then you can use: enman-demo setup my-cool-project /path/to/target"
        ;;
    setup)
        "$SCRIPT_DIR/setup.sh" "$@"
        ;;
    scan)
        "$SCRIPT_DIR/scan.sh" "$@"
        ;;
    projects)
        "$SCRIPT_DIR/projects.sh" "$@"
        ;;
    environments)
        "$SCRIPT_DIR/environments.sh" "$@"
        ;;
    export)
        "$SCRIPT_DIR/export.sh" "$@"
        ;;
    import)
        "$SCRIPT_DIR/import.sh" "$@"
        ;;
    update)
        "$SCRIPT_DIR/update.sh"
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo ""
        echo "Available commands:"
        echo "  init                                                                  - Add 'enman-demo' alias to shell config"
        echo "  setup <project-name> <target-directory> [--env <env>]                - Copy project files to target directory"
        echo "  scan <project-name> [directory] [--env <env>] [--include <pattern>]... - Scan directory for files and save to project"
        echo "  projects <action> [arguments]                                        - Manage projects (create, list, archive, delete)"
        echo "  environments <action> <project-name> [env-name]                      - Manage environments (list, create, delete)"
        echo "  export <project-name> [--env <env>] [--output <file>]                - Bundle a project (or env) as a tar.gz archive"
        echo "  import <file> [--project <name>] [--env <env>]                       - Restore a project (or env) from a bundle"
        echo "  update                                                               - Update enman to the latest version"
        exit 1
        ;;
esac
