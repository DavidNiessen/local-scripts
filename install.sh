#!/bin/bash

set -e

# install.sh
# Installs local-scripts by symlinking them to ~/.local/bin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_SOURCE_DIR="$SCRIPT_DIR/scripts"
INSTALL_DIR="$HOME/.local/bin"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Local Scripts Installer                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if uninstall flag is provided
if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
    echo "Uninstalling local-scripts..."
    echo ""

    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Warning: $INSTALL_DIR does not exist. Nothing to uninstall.${NC}"
        exit 0
    fi

    removed_count=0
    for script in "$SCRIPTS_SOURCE_DIR"/*.sh; do
        script_name=$(basename "$script")
        target_link="$INSTALL_DIR/$script_name"

        if [ -L "$target_link" ]; then
            link_target=$(readlink "$target_link")
            if [ "$link_target" = "$script" ]; then
                rm "$target_link"
                echo -e "${GREEN}✓${NC} Removed: $script_name"
                ((removed_count++))
            fi
        fi
    done

    echo ""
    if [ $removed_count -gt 0 ]; then
        echo -e "${GREEN}Successfully uninstalled $removed_count script(s)${NC}"
    else
        echo -e "${YELLOW}No scripts were found to uninstall${NC}"
    fi
    exit 0
fi

# Create install directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    echo -e "${GREEN}✓${NC} Created $INSTALL_DIR"
    echo ""
fi

# Check if install directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH${NC}"
    echo ""

    # Detect shell
    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        zsh)
            CONFIG_FILE="$HOME/.zshrc"
            ;;
        bash)
            CONFIG_FILE="$HOME/.bashrc"
            ;;
        *)
            CONFIG_FILE=""
            ;;
    esac

    if [ -n "$CONFIG_FILE" ]; then
        echo "Add the following to your $CONFIG_FILE:"
        echo ""
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        echo "Then run: source $CONFIG_FILE"
        echo ""
        read -p "Would you like me to add it automatically? [y/N] " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$CONFIG_FILE" 2>/dev/null; then
                echo "" >> "$CONFIG_FILE"
                echo "# Local scripts directory" >> "$CONFIG_FILE"
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$CONFIG_FILE"
                echo -e "${GREEN}✓${NC} Added to $CONFIG_FILE"
                echo ""
                echo -e "${YELLOW}Note: Run 'source $CONFIG_FILE' or restart your terminal${NC}"
            else
                echo -e "${YELLOW}PATH entry already exists in $CONFIG_FILE${NC}"
            fi
            echo ""
        fi
    fi
fi

# Find all .sh files in scripts directory
echo "Installing scripts..."
echo ""

installed_count=0
updated_count=0
skipped_count=0

for script in "$SCRIPTS_SOURCE_DIR"/*.sh; do
    if [ ! -f "$script" ]; then
        continue
    fi

    script_name=$(basename "$script")
    target_link="$INSTALL_DIR/$script_name"

    # Check if symlink already exists
    if [ -L "$target_link" ]; then
        existing_target=$(readlink "$target_link")
        if [ "$existing_target" = "$script" ]; then
            echo -e "${YELLOW}⊙${NC} Already installed: $script_name"
            ((skipped_count++))
        else
            # Update symlink to point to new location
            rm "$target_link"
            ln -s "$script" "$target_link"
            echo -e "${GREEN}✓${NC} Updated: $script_name"
            ((updated_count++))
        fi
    elif [ -e "$target_link" ]; then
        echo -e "${RED}✗${NC} Conflict: $target_link exists but is not a symlink"
        ((skipped_count++))
    else
        # Create new symlink
        ln -s "$script" "$target_link"
        echo -e "${GREEN}✓${NC} Installed: $script_name"
        ((installed_count++))
    fi
done

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Summary                                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Installed: $installed_count"
echo "Updated: $updated_count"
echo "Skipped: $skipped_count"
echo ""

if [ $installed_count -gt 0 ] || [ $updated_count -gt 0 ]; then
    echo -e "${GREEN}✓ Installation complete!${NC}"
    echo ""
    echo "You can now run scripts from anywhere, e.g.:"
    echo "  global-claude-code-model.sh claude-opus-4-7"
    echo "  reset-project-workspaces.sh --dry-run"
    echo ""
    echo "To uninstall, run: ./install.sh --uninstall"
fi