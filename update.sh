#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify this is a git repo (i.e. installed via install.sh)
if [ ! -d "$SCRIPT_DIR/.git" ]; then
    echo "Error: enman installation is not a git repo."
    echo "Re-install with:"
    echo "  curl -sSL https://raw.githubusercontent.com/ibedwi/enman/main/install.sh | bash"
    exit 1
fi

echo "Updating enman..."

# Fetch and show what will change
git -C "$SCRIPT_DIR" fetch origin main

LOCAL=$(git -C "$SCRIPT_DIR" rev-parse HEAD)
REMOTE=$(git -C "$SCRIPT_DIR" rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "Already up to date."
    exit 0
fi

git -C "$SCRIPT_DIR" pull --ff-only origin main

# Ensure scripts are executable after update
chmod +x "$SCRIPT_DIR/main.sh" \
         "$SCRIPT_DIR/setup.sh" \
         "$SCRIPT_DIR/scan.sh" \
         "$SCRIPT_DIR/projects.sh" \
         "$SCRIPT_DIR/update.sh"

echo ""
echo "enman updated successfully!"
