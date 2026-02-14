#!/bin/bash

# Check if both arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <project-name> <target-directory>"
    echo "Example: $0 my-cool-project /path/to/target"
    echo ""
    echo "This script will:"
    echo "  1. Find all .env files in ~/.enman/projects/<project-name>"
    echo "  2. Copy them to the target directory preserving the directory structure"
    exit 1
fi

PROJECT_NAME="$1"
TARGET_DIR="$2"

# Base directory for enman data
ENMAN_DIR="${ENMAN_HOME:-$HOME/.enman}"
SOURCE_DIR="$ENMAN_DIR/projects/$PROJECT_NAME"

# Check if the project directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Project directory does not exist: $SOURCE_DIR"
    echo "Please ensure the project '$PROJECT_NAME' has been created"
    exit 1
fi

# Check if target directory exists, create if not
if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory does not exist. Creating: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

echo "Copying .env files from $SOURCE_DIR to $TARGET_DIR"
echo "Searching for all .env files in the source directory..."
echo ""

# Counter for copied files
COPIED_COUNT=0

# Find all .env files in the source directory and copy them
find "$SOURCE_DIR" -name ".env" -type f 2>/dev/null | while read -r env_file; do
    # Get relative path from source directory
    rel_path="${env_file#$SOURCE_DIR/}"

    # Skip the script itself if it's named .env
    if [ "$rel_path" = ".env" ]; then
        continue
    fi

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
TOTAL_FILES=$(find "$SOURCE_DIR" -name ".env" -type f 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "Done! Copied $TOTAL_FILES .env file(s) to $TARGET_DIR"
