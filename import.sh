#!/bin/bash

# Base directory for enman data
ENMAN_DIR="${ENMAN_HOME:-$HOME/.enman}"
PROJECTS_DIR="$ENMAN_DIR/projects"

# Parse arguments
POSITIONAL_ARGS=()
PROJECT_OVERRIDE=""
ENV_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo "Error: --project requires a name argument"
                exit 1
            fi
            PROJECT_OVERRIDE="$2"
            shift 2
            ;;
        --env)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo "Error: --env requires an environment name argument"
                exit 1
            fi
            ENV_OVERRIDE="$2"
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

BUNDLE_FILE="${POSITIONAL_ARGS[0]:-}"

if [ -z "$BUNDLE_FILE" ]; then
    echo "Usage: $0 <file> [--project <name>] [--env <env>]"
    echo ""
    echo "Restores a project or environment bundle produced by 'enman export'."
    echo ""
    echo "Options:"
    echo "  --project <name>  Import under a different project name"
    echo "  --env <env>       Rename the env on import (only for env-scoped bundles)"
    exit 1
fi

if [ ! -f "$BUNDLE_FILE" ]; then
    echo "Error: Bundle file does not exist: $BUNDLE_FILE"
    exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if ! tar -xzf "$BUNDLE_FILE" -C "$TMP_DIR"; then
    echo "Error: Failed to extract bundle"
    exit 1
fi

mkdir -p "$PROJECTS_DIR"

if [ -f "$TMP_DIR/.enman-export" ]; then
    # Env-scoped bundle
    SCOPE=""
    SRC_PROJECT=""
    SRC_ENV=""
    while IFS='=' read -r key value; do
        case "$key" in
            scope) SCOPE="$value" ;;
            project) SRC_PROJECT="$value" ;;
            env) SRC_ENV="$value" ;;
        esac
    done < "$TMP_DIR/.enman-export"

    if [ "$SCOPE" != "env" ]; then
        echo "Error: Bundle marker has unexpected scope '$SCOPE'"
        exit 1
    fi

    if [ ! -d "$TMP_DIR/environments/$SRC_ENV" ]; then
        echo "Error: Bundle is missing environment directory '$SRC_ENV'"
        exit 1
    fi

    TARGET_PROJECT="${PROJECT_OVERRIDE:-$SRC_PROJECT}"
    TARGET_ENV="${ENV_OVERRIDE:-$SRC_ENV}"

    TARGET_PROJECT_PATH="$PROJECTS_DIR/$TARGET_PROJECT"
    TARGET_ENV_PATH="$TARGET_PROJECT_PATH/environments/$TARGET_ENV"

    if [ -d "$TARGET_ENV_PATH" ]; then
        echo "Environment '$TARGET_ENV' already exists for project '$TARGET_PROJECT'."
        echo "Overwrite? [y/N]: "
        read -r CONFIRM
        if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
            echo "Import aborted."
            exit 1
        fi
        rm -rf "$TARGET_ENV_PATH"
    fi

    mkdir -p "$TARGET_PROJECT_PATH/environments"
    mv "$TMP_DIR/environments/$SRC_ENV" "$TARGET_ENV_PATH"

    echo "Imported environment '$TARGET_ENV' into project '$TARGET_PROJECT'"
else
    # Project-scoped bundle: expect a single top-level dir containing environments/
    if [ -n "$ENV_OVERRIDE" ]; then
        echo "Error: --env is only valid for env-scoped bundles"
        exit 1
    fi

    SRC_PROJECT_DIR=""
    shopt -s dotglob nullglob
    for entry in "$TMP_DIR"/*; do
        if [ -d "$entry" ]; then
            if [ -n "$SRC_PROJECT_DIR" ]; then
                shopt -u dotglob nullglob
                echo "Error: Bundle has multiple top-level directories; cannot determine project"
                exit 1
            fi
            SRC_PROJECT_DIR="$entry"
        fi
    done
    shopt -u dotglob nullglob

    if [ -z "$SRC_PROJECT_DIR" ] || [ ! -d "$SRC_PROJECT_DIR/environments" ]; then
        echo "Error: Bundle does not look like an enman project export"
        exit 1
    fi

    SRC_PROJECT="$(basename "$SRC_PROJECT_DIR")"
    TARGET_PROJECT="${PROJECT_OVERRIDE:-$SRC_PROJECT}"
    TARGET_PROJECT_PATH="$PROJECTS_DIR/$TARGET_PROJECT"

    if [ -d "$TARGET_PROJECT_PATH" ]; then
        echo "Project '$TARGET_PROJECT' already exists."
        echo "Overwrite? [y/N]: "
        read -r CONFIRM
        if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
            echo "Import aborted."
            exit 1
        fi
        rm -rf "$TARGET_PROJECT_PATH"
    fi

    mv "$SRC_PROJECT_DIR" "$TARGET_PROJECT_PATH"

    echo "Imported project '$TARGET_PROJECT'"
fi
