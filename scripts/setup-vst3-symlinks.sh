#!/usr/bin/env bash

set -euo pipefail

OS="$(uname -s)"

case "$OS" in
    Darwin)
        VST3_DIR="/Library/Audio/Plug-Ins/VST3"

        if [ "${EUID:-$(id -u)}" -ne 0 ]; then
            echo "Error: On macOS, this script must be run with sudo."
            exit 1
        fi
        ;;

    Linux)
        VST3_DIR="$HOME/.vst3"
        ;;

    MINGW*|MSYS*|CYGWIN*)
        VST3_DIR="/c/Program Files/Common Files/VST3"

        if ! mkdir -p "$(dirname "$VST3_DIR")" 2>/dev/null; then
            echo "Error: Run this script from an Administrator shell."
            exit 1
        fi
        ;;

    *)
        echo "Error: Unsupported operating system: $OS"
        exit 1
        ;;
esac

echo "VST3 Redirect Setup"
echo "VST3 path: $VST3_DIR"
echo

# Refuse to overwrite an existing path
if [ -e "$VST3_DIR" ] || [ -L "$VST3_DIR" ]; then
    echo "WARNING: '$VST3_DIR' already exists."
    echo "No changes have been made."
    exit 1
fi

read -r -p "Enter the directory to redirect VST3 plugins to: " TARGET_DIR

# Expand ~
case "$TARGET_DIR" in
    "~")
        TARGET_DIR="$HOME"
        ;;
    "~/"*)
        TARGET_DIR="$HOME/${TARGET_DIR#~/}"
        ;;
esac

if [ -z "$TARGET_DIR" ]; then
    echo "Error: No path provided."
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory does not exist:"
    echo "  $TARGET_DIR"
    exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

ln -s "$TARGET_DIR" "$VST3_DIR"

echo
echo "Success!"
echo "Created symlink:"
echo "  $VST3_DIR -> $TARGET_DIR"