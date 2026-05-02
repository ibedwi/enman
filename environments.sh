#!/bin/bash

# Base directory for enman data
ENMAN_DIR="${ENMAN_HOME:-$HOME/.enman}"
PROJECTS_DIR="$ENMAN_DIR/projects"

ensure_migrated() {
    local project_path="$1"
    [ -d "$project_path/environments" ] && return 0
    local has_files=0
    for entry in "$project_path"/* "$project_path"/.[!.]*; do
        [ -e "$entry" ] || continue
        case "$(basename "$entry")" in
            .archived|environments) ;;
            *) has_files=1; break ;;
        esac
    done
    mkdir -p "$project_path/environments/development"
    if [ "$has_files" = "1" ]; then
        shopt -s dotglob nullglob
        for entry in "$project_path"/*; do
            local name="$(basename "$entry")"
            [ "$name" = ".archived" ] && continue
            [ "$name" = "environments" ] && continue
            mv "$entry" "$project_path/environments/development/"
        done
        shopt -u dotglob nullglob
        echo "Migrated existing files into environments/development/"
    fi
}

if [ -z "$1" ]; then
    echo "Usage: $0 <action> <project-name> [env-name]"
    echo ""
    echo "Actions:"
    echo "  list <project-name>               - List environments for a project"
    echo "  create <project-name> <env-name>  - Create a new environment"
    echo "  delete <project-name> <env-name>  - Delete an environment"
    exit 1
fi

ACTION="$1"
shift

case "$ACTION" in
    list)
        PROJECT_NAME="$1"

        if [ -z "$PROJECT_NAME" ]; then
            echo "Error: Project name is required"
            echo "Usage: environments list <project-name>"
            exit 1
        fi

        PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

        if [ ! -d "$PROJECT_PATH" ]; then
            echo "Error: Project '$PROJECT_NAME' does not exist"
            exit 1
        fi

        ensure_migrated "$PROJECT_PATH"

        ENVS_DIR="$PROJECT_PATH/environments"

        if [ ! -d "$ENVS_DIR" ] || [ -z "$(ls -A "$ENVS_DIR" 2>/dev/null)" ]; then
            echo "No environments found for project '$PROJECT_NAME'."
            exit 0
        fi

        echo "Environments for '$PROJECT_NAME':"
        for dir in "$ENVS_DIR"/*/; do
            [ -d "$dir" ] || continue
            name="$(basename "$dir")"
            # Determine if env directory is empty (excluding metadata)
            file_count=$(find "$dir" -type f ! -name ".archived" ! -name ".enman" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$file_count" = "0" ]; then
                echo "  $name [empty]"
            else
                echo "  $name"
            fi
        done
        ;;

    create)
        PROJECT_NAME="$1"
        ENV_NAME="$2"

        if [ -z "$PROJECT_NAME" ] || [ -z "$ENV_NAME" ]; then
            echo "Error: Project name and environment name are required"
            echo "Usage: environments create <project-name> <env-name>"
            exit 1
        fi

        PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

        if [ ! -d "$PROJECT_PATH" ]; then
            echo "Error: Project '$PROJECT_NAME' does not exist"
            exit 1
        fi

        ensure_migrated "$PROJECT_PATH"

        ENV_PATH="$PROJECT_PATH/environments/$ENV_NAME"

        if [ -d "$ENV_PATH" ]; then
            echo "Error: Environment '$ENV_NAME' already exists for project '$PROJECT_NAME'"
            exit 1
        fi

        mkdir -p "$ENV_PATH"
        echo "Environment '$ENV_NAME' created for project '$PROJECT_NAME'"
        ;;

    delete)
        PROJECT_NAME="$1"
        ENV_NAME="$2"

        if [ -z "$PROJECT_NAME" ] || [ -z "$ENV_NAME" ]; then
            echo "Error: Project name and environment name are required"
            echo "Usage: environments delete <project-name> <env-name>"
            exit 1
        fi

        PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

        if [ ! -d "$PROJECT_PATH" ]; then
            echo "Error: Project '$PROJECT_NAME' does not exist"
            exit 1
        fi

        ensure_migrated "$PROJECT_PATH"

        ENV_PATH="$PROJECT_PATH/environments/$ENV_NAME"

        if [ ! -d "$ENV_PATH" ]; then
            echo "Error: Environment '$ENV_NAME' does not exist for project '$PROJECT_NAME'"
            exit 1
        fi

        echo "Are you sure you want to delete environment '$ENV_NAME' from project '$PROJECT_NAME'?"
        echo "Type the environment name to confirm: "
        read -r CONFIRM

        if [ "$CONFIRM" != "$ENV_NAME" ]; then
            echo "Confirmation failed. Environment not deleted."
            exit 1
        fi

        rm -rf "$ENV_PATH"
        echo "Environment '$ENV_NAME' deleted from project '$PROJECT_NAME'"
        ;;

    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        echo "Actions:"
        echo "  list <project-name>               - List environments for a project"
        echo "  create <project-name> <env-name>  - Create a new environment"
        echo "  delete <project-name> <env-name>  - Delete an environment"
        exit 1
        ;;
esac
