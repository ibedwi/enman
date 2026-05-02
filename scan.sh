#!/bin/bash

# Base directory for enman data
ENMAN_DIR="${ENMAN_HOME:-$HOME/.enman}"
PROJECTS_DIR="$ENMAN_DIR/projects"

# Parse arguments
INCLUDE_PATTERNS=()
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo "Error: --include requires a pattern argument"
                exit 1
            fi
            INCLUDE_PATTERNS+=("$2")
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
SCAN_DIR="${POSITIONAL_ARGS[1]:-$(pwd)}"

# Default to .env when no --include provided
if [ ${#INCLUDE_PATTERNS[@]} -eq 0 ]; then
    INCLUDE_PATTERNS=(".env")
fi

# Check if project name is provided
if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name> [scan-directory] [--include <pattern>]..."
    echo ""
    echo "Examples:"
    echo "  $0 my-app"
    echo "  $0 my-app /path/to/monorepo"
    echo "  $0 my-app --include \".env*\""
    echo "  $0 my-app --include \".env*\" --include \"config.yaml\""
    echo "  $0 my-app /path/to/monorepo --include \".env*\""
    echo ""
    echo "Options:"
    echo "  --include <pattern>  File pattern to scan for (can be repeated)"
    echo "                       Defaults to '.env' if not specified"
    echo ""
    echo "This script will:"
    echo "  1. Recursively scan the directory for matching files"
    echo "  2. Copy them to ~/.enman/projects/<project-name> preserving directory structure"
    echo "  3. Write a .enman manifest listing all included files"
    echo ""
    echo "If no scan directory is provided, the current working directory is used."
    exit 1
fi

# Resolve to absolute path
SCAN_DIR="$(cd "$SCAN_DIR" 2>/dev/null && pwd)"

if [ -z "$SCAN_DIR" ] || [ ! -d "$SCAN_DIR" ]; then
    echo "Error: Directory does not exist: ${POSITIONAL_ARGS[1]:-$(pwd)}"
    exit 1
fi

PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_PATH" ]; then
    mkdir -p "$PROJECT_PATH"
    echo "Created project '$PROJECT_NAME'"
fi

echo "Scanning for files matching: ${INCLUDE_PATTERNS[*]}"
echo "Directory: $SCAN_DIR"
echo ""

# Build find expression dynamically
FIND_EXPR=()
for i in "${!INCLUDE_PATTERNS[@]}"; do
    [ "$i" -gt 0 ] && FIND_EXPR+=("-o")
    FIND_EXPR+=("-name" "${INCLUDE_PATTERNS[$i]}")
done

# Find matching files, pruning .git directories
ENV_FILES=$(find "$SCAN_DIR" -path "*/.git" -prune -o \( "${FIND_EXPR[@]}" \) -type f -print 2>/dev/null)

if [ -z "$ENV_FILES" ]; then
    echo "No files found matching: ${INCLUDE_PATTERNS[*]}"
    exit 0
fi

# Display found files
echo "Found files:"
TOTAL=0
while IFS= read -r env_file; do
    rel_path="${env_file#$SCAN_DIR/}"
    echo "  $rel_path"
    TOTAL=$((TOTAL + 1))
done <<< "$ENV_FILES"

echo ""
echo "These files will be copied to: $PROJECT_PATH"
echo ""

# Copy files preserving directory structure
COPIED=0
while IFS= read -r env_file; do
    rel_path="${env_file#$SCAN_DIR/}"
    target_file="$PROJECT_PATH/$rel_path"
    target_dir="$(dirname "$target_file")"

    mkdir -p "$target_dir"
    cp "$env_file" "$target_file"
    echo "  Copied: $rel_path"
    COPIED=$((COPIED + 1))
done <<< "$ENV_FILES"

# Write manifest to project directory
MANIFEST="$PROJECT_PATH/.enman"
{
    echo "# Enman project manifest"
    echo "# Scanned from: $SCAN_DIR"
    echo "# Patterns: ${INCLUDE_PATTERNS[*]}"
    echo "#"
    echo "# Included files:"
    while IFS= read -r env_file; do
        rel_path="${env_file#$SCAN_DIR/}"
        echo "$rel_path"
    done <<< "$ENV_FILES"
} > "$MANIFEST"

echo ""
echo "Done! Copied $COPIED file(s) to project '$PROJECT_NAME'"
