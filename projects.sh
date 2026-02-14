#!/bin/bash

# Base directory for enman data
ENMAN_DIR="${ENMAN_HOME:-$HOME/.enman}"
PROJECTS_DIR="$ENMAN_DIR/projects"

# Check if action is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <action> [arguments]"
    echo ""
    echo "Actions:"
    echo "  create <project-name>  - Create a new project"
    echo "  list                   - List all projects"
    echo "  archive <project-name> - Archive a project"
    echo "  delete <project-name>  - Delete a project"
    exit 1
fi

ACTION="$1"
shift

case "$ACTION" in
    create)
        PROJECT_NAME="$1"

        if [ -z "$PROJECT_NAME" ]; then
            echo "Error: Project name is required"
            echo "Usage: projects create <project-name>"
            exit 1
        fi

        PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

        if [ -d "$PROJECT_PATH" ]; then
            echo "Error: Project '$PROJECT_NAME' already exists"
            exit 1
        fi

        mkdir -p "$PROJECT_PATH"
        echo "Project '$PROJECT_NAME' created at $PROJECT_PATH"
        ;;

    list)
        if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null)" ]; then
            echo "No projects found."
            exit 0
        fi

        echo "Projects:"
        for dir in "$PROJECTS_DIR"/*/; do
            [ -d "$dir" ] || continue
            name="$(basename "$dir")"
            if [ -f "$dir/.archived" ]; then
                echo "  $name [archived]"
            else
                echo "  $name"
            fi
        done
        ;;

    archive)
        PROJECT_NAME="$1"

        if [ -z "$PROJECT_NAME" ]; then
            echo "Error: Project name is required"
            echo "Usage: projects archive <project-name>"
            exit 1
        fi

        PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

        if [ ! -d "$PROJECT_PATH" ]; then
            echo "Error: Project '$PROJECT_NAME' does not exist"
            exit 1
        fi

        if [ -f "$PROJECT_PATH/.archived" ]; then
            echo "Error: Project '$PROJECT_NAME' is already archived"
            exit 1
        fi

        touch "$PROJECT_PATH/.archived"
        echo "Project '$PROJECT_NAME' archived"
        ;;

    delete)
        PROJECT_NAME="$1"

        if [ -z "$PROJECT_NAME" ]; then
            echo "Error: Project name is required"
            echo "Usage: projects delete <project-name>"
            exit 1
        fi

        PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

        if [ ! -d "$PROJECT_PATH" ]; then
            echo "Error: Project '$PROJECT_NAME' does not exist"
            exit 1
        fi

        echo "Are you sure you want to delete project '$PROJECT_NAME'?"
        echo "Type the project name to confirm: "
        read -r CONFIRM

        if [ "$CONFIRM" != "$PROJECT_NAME" ]; then
            echo "Confirmation failed. Project not deleted."
            exit 1
        fi

        rm -rf "$PROJECT_PATH"
        echo "Project '$PROJECT_NAME' deleted"
        ;;

    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        echo "Actions:"
        echo "  create <project-name>  - Create a new project"
        echo "  list                   - List all projects"
        echo "  archive <project-name> - Archive a project"
        echo "  delete <project-name>  - Delete a project"
        exit 1
        ;;
esac
