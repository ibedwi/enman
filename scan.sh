#!/bin/bash

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$SCRIPT_DIR/projects"

# Check if project name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <project-name> [scan-directory]"
    echo "Example: $0 my-app"
    echo "Example: $0 my-app /path/to/monorepo"
    echo ""
    echo "This script will:"
    echo "  1. Recursively scan the directory for .env files"
    echo "  2. Copy them to ./projects/<project-name> preserving directory structure"
    echo ""
    echo "If no scan directory is provided, the current working directory is used."
    exit 1
fi

PROJECT_NAME="$1"
SCAN_DIR="${2:-$(pwd)}"

# Resolve to absolute path
SCAN_DIR="$(cd "$SCAN_DIR" 2>/dev/null && pwd)"

if [ -z "$SCAN_DIR" ] || [ ! -d "$SCAN_DIR" ]; then
    echo "Error: Directory does not exist: ${2:-$(pwd)}"
    exit 1
fi

PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_PATH" ]; then
    mkdir -p "$PROJECT_PATH"
    echo "Created project '$PROJECT_NAME'"
fi

echo "Scanning for .env files in: $SCAN_DIR"
echo ""

# Find all .env files
ENV_FILES=$(find "$SCAN_DIR" -name ".env" -type f 2>/dev/null)

if [ -z "$ENV_FILES" ]; then
    echo "No .env files found in $SCAN_DIR"
    exit 0
fi

# Display found files
echo "Found .env files:"
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

echo ""
echo "Done! Copied $COPIED .env file(s) to project '$PROJECT_NAME'"
