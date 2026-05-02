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

# Parse arguments
POSITIONAL_ARGS=()
ENV_NAME=""
OUTPUT_FILE=""

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
        --output)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo "Error: --output requires a file path argument"
                exit 1
            fi
            OUTPUT_FILE="$2"
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

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name> [--env <env>] [--output <file>]"
    echo ""
    echo "Bundles a project (or a single environment) into a tar.gz archive."
    echo ""
    echo "Options:"
    echo "  --env <name>     Export only the named environment"
    echo "  --output <file>  Output archive path (default: ./<project>-<timestamp>.tar.gz)"
    exit 1
fi

PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Project '$PROJECT_NAME' does not exist"
    exit 1
fi

ensure_migrated "$PROJECT_PATH"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

if [ -n "$ENV_NAME" ]; then
    ENV_PATH="$PROJECT_PATH/environments/$ENV_NAME"
    if [ ! -d "$ENV_PATH" ]; then
        echo "Error: Environment '$ENV_NAME' does not exist for project '$PROJECT_NAME'"
        exit 1
    fi

    if [ -z "$OUTPUT_FILE" ]; then
        OUTPUT_FILE="./${PROJECT_NAME}-${ENV_NAME}-${TIMESTAMP}.tar.gz"
    fi

    # Stage the env-scoped layout in a temp dir so the archive paths are clean
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    {
        echo "scope=env"
        echo "project=$PROJECT_NAME"
        echo "env=$ENV_NAME"
    } > "$TMP_DIR/.enman-export"

    mkdir -p "$TMP_DIR/environments"
    cp -R "$ENV_PATH" "$TMP_DIR/environments/$ENV_NAME"

    tar -czf "$OUTPUT_FILE" -C "$TMP_DIR" .enman-export environments

    echo "Exported environment '$ENV_NAME' of project '$PROJECT_NAME' to $OUTPUT_FILE"
else
    if [ -z "$OUTPUT_FILE" ]; then
        OUTPUT_FILE="./${PROJECT_NAME}-${TIMESTAMP}.tar.gz"
    fi

    # Archive the project dir directly so it untars as <project>/environments/...
    tar -czf "$OUTPUT_FILE" -C "$PROJECTS_DIR" "$PROJECT_NAME"

    echo "Exported project '$PROJECT_NAME' to $OUTPUT_FILE"
fi
