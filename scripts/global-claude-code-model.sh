#!/bin/bash

set -e

# global-claude-code-model.sh
# Sets the Claude Code model globally by configuring ANTHROPIC_MODEL environment variable

MODEL_NAME="$1"

# Usage message
usage() {
    echo "Usage: $0 <model-name>"
    echo ""
    echo "Example: $0 claude-opus-4-7"
    exit 1
}

# Validate arguments
if [ -z "$MODEL_NAME" ]; then
    echo "Error: Model name is required"
    echo ""
    usage
fi

# Detect shell and config file
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    zsh)
        CONFIG_FILE="$HOME/.zshrc"
        ;;
    bash)
        CONFIG_FILE="$HOME/.bashrc"
        ;;
    *)
        echo "Error: Unsupported shell '$SHELL_NAME'. Only bash and zsh are supported."
        exit 1
        ;;
esac

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Warning: Config file $CONFIG_FILE does not exist. Creating it now."
    touch "$CONFIG_FILE"
fi

# Check if ANTHROPIC_MODEL is already set in the config file
if grep -q "^export ANTHROPIC_MODEL=" "$CONFIG_FILE"; then
    echo "Found existing ANTHROPIC_MODEL configuration in $CONFIG_FILE"
    echo "Updating to: $MODEL_NAME"

    # Create backup
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"

    # Update existing line (works on both macOS and Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|^export ANTHROPIC_MODEL=.*|export ANTHROPIC_MODEL=\"$MODEL_NAME\"|" "$CONFIG_FILE"
    else
        # Linux
        sed -i "s|^export ANTHROPIC_MODEL=.*|export ANTHROPIC_MODEL=\"$MODEL_NAME\"|" "$CONFIG_FILE"
    fi

    echo "Backup saved to: $CONFIG_FILE.backup"
else
    echo "Adding ANTHROPIC_MODEL configuration to $CONFIG_FILE"
    echo "" >> "$CONFIG_FILE"
    echo "# Claude Code model configuration" >> "$CONFIG_FILE"
    echo "export ANTHROPIC_MODEL=\"$MODEL_NAME\"" >> "$CONFIG_FILE"
fi

echo ""
echo "✓ Successfully configured Claude Code to use model: $MODEL_NAME"
echo ""
echo "To apply the changes:"
echo "  1. Run: source $CONFIG_FILE"
echo "  2. Close and reopen your terminal"
echo ""
echo "Verify with: echo \$ANTHROPIC_MODEL"
echo "Or use /status in Claude Code"