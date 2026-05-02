#!/bin/bash

# Base directory for enman data
ENMAN_DIR="${ENMAN_HOME:-$HOME/.enman}"

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

# Parse arguments
POSITIONAL_ARGS=()
ENV_NAME="development"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo "Error: --env requires an environment name argument"
                exit 1
            fi
            ENV_NAME="$2"
            shift 2
            ;;
        -*)
            echo "Error: Unknown flag '$1'"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

PROJECT_NAME="${POSITIONAL_ARGS[0]:-}"
TARGET_DIR="${POSITIONAL_ARGS[1]:-}"

# Check if both arguments are provided
if [ -z "$PROJECT_NAME" ] || [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <project-name> <target-directory> [--env <env>]"
    echo "Example: $0 my-cool-project /path/to/target"
    echo "Example: $0 my-cool-project /path/to/target --env staging"
    echo ""
    echo "This script will:"
    echo "  1. Find all files in ~/.enman/projects/<project-name>/environments/<env>/"
    echo "  2. Copy them to the target directory preserving the directory structure"
    echo ""
    echo "Options:"
    echo "  --env <name>  Environment to use (default: development)"
    exit 1
fi

PROJECT_PATH="$ENMAN_DIR/projects/$PROJECT_NAME"

# Check if the project directory exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project directory does not exist: $PROJECT_PATH"
    echo "Please ensure the project '$PROJECT_NAME' has been created"
    exit 1
fi

ensure_migrated "$PROJECT_PATH"

SOURCE_DIR="$PROJECT_PATH/environments/$ENV_NAME"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Environment '$ENV_NAME' does not exist for project '$PROJECT_NAME'"
    if [ -d "$PROJECT_PATH/environments" ]; then
        echo "Available environments:"
        for dir in "$PROJECT_PATH/environments"/*/; do
            [ -d "$dir" ] || continue
            echo "  $(basename "$dir")"
        done
    fi
    exit 1
fi

# Check if target directory exists, create if not
if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory does not exist. Creating: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

echo "Copying files from $SOURCE_DIR to $TARGET_DIR"
echo "Environment: $ENV_NAME"
echo "Searching for files in the source directory..."
echo ""

# Counter for copied files
COPIED_COUNT=0

# Find all files in the source directory, excluding metadata files
find "$SOURCE_DIR" -type f ! -name ".archived" ! -name ".enman" 2>/dev/null | while read -r env_file; do
    # Get relative path from source directory
    rel_path="${env_file#$SOURCE_DIR/}"

    # Get the directory part
    target_file="$TARGET_DIR/$rel_path"
    target_dir="$(dirname "$target_file")"

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Copy the file
    cp "$env_file" "$target_file"
    echo "✓ Copied: $rel_path"
    COPIED_COUNT=$((COPIED_COUNT + 1))
done

# Note: COPIED_COUNT won't work in the while loop due to subshell
# So we'll count again for the summary
TOTAL_FILES=$(find "$SOURCE_DIR" -type f ! -name ".archived" ! -name ".enman" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "Done! Copied $TOTAL_FILES file(s) to $TARGET_DIR"
