#!/bin/bash
set -e

ENMAN_DIR="${ENMAN_HOME:-$HOME/.enman}"
INSTALL_DIR="$ENMAN_DIR/bin"
REPO_URL="https://github.com/ibedwi/enman.git"

echo "Installing enman..."
echo ""

# Check for git
if ! command -v git &>/dev/null; then
    echo "Error: git is required but not installed."
    exit 1
fi

# Clone or update the repo
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing installation..."
    git -C "$INSTALL_DIR" pull --ff-only
else
    if [ -d "$INSTALL_DIR" ]; then
        echo "Error: $INSTALL_DIR already exists but is not a git repo."
        echo "Remove it and re-run the installer:"
        echo "  rm -rf $INSTALL_DIR"
        exit 1
    fi
    mkdir -p "$ENMAN_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Make scripts executable
chmod +x "$INSTALL_DIR/main.sh" \
         "$INSTALL_DIR/setup.sh" \
         "$INSTALL_DIR/scan.sh" \
         "$INSTALL_DIR/projects.sh"

# Determine shell config file
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "$(which zsh 2>/dev/null)" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "$(which bash 2>/dev/null)" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -z "$SHELL_CONFIG" ]; then
    echo ""
    echo "Could not detect shell config. Add this alias manually:"
    echo "  alias enman='$INSTALL_DIR/main.sh'"
else
    ALIAS_LINE="alias enman='$INSTALL_DIR/main.sh'"

    # Remove existing alias if present
    if grep -q "alias enman=" "$SHELL_CONFIG" 2>/dev/null; then
        grep -v "alias enman=" "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp"
        mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"
    fi

    # Add the alias
    echo "" >> "$SHELL_CONFIG"
    echo "# enman" >> "$SHELL_CONFIG"
    echo "$ALIAS_LINE" >> "$SHELL_CONFIG"
fi

echo ""
echo "enman installed successfully!"
echo ""
echo "To get started, run:"
if [ -n "$SHELL_CONFIG" ]; then
    echo "  source $SHELL_CONFIG"
fi
echo "  enman --help"
