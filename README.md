# Local Scripts Collection

A collection of utility scripts for managing local development environment and IntelliJ IDEA projects.

## Installation

### Quick Install (Recommended)

Run the installer to make all scripts available globally:

```bash
./install.sh
```

This will:
- Create `~/.local/bin` if it doesn't exist
- Symlink all scripts to `~/.local/bin`
- Optionally add `~/.local/bin` to your PATH
- Allow you to run scripts from anywhere without the `.sh` extension

After installation, you can run scripts from anywhere:
```bash
global-claude-code-model.sh claude-opus-4-7
reset-project-workspaces.sh --dry-run
```

### Uninstall

To remove all installed scripts:
```bash
./install.sh --uninstall
```

### Manual Installation

Alternatively, you can manually add the scripts directory to your PATH:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$PATH:/Users/username/IdeaProjects/private/local-scripts/scripts"
```

## Scripts

### global-claude-code-model.sh

Sets the Claude Code model globally by configuring the `ANTHROPIC_MODEL` environment variable in your shell configuration file.

#### Features

- **Cross-platform**: Works on both Linux and macOS
- **Auto-detection**: Automatically detects shell type (bash/zsh) and config file
- **Safe updates**: Creates backup before modifying existing configuration
- **Clear instructions**: Provides step-by-step guidance for applying changes

#### Usage

```bash
# Set model globally
./scripts/global-claude-code-model.sh claude-opus-4-7

# Other examples
./scripts/global-claude-code-model.sh claude-sonnet-4-6
./scripts/global-claude-code-model.sh claude-haiku-4-5-20251001
```

#### What it does

1. Detects your shell (bash or zsh)
2. Adds or updates `export ANTHROPIC_MODEL="<model-name>"` in your shell config file (~/.zshrc or ~/.bashrc)
3. Creates a backup of your config file before making changes
4. Provides instructions for applying the changes

#### After running

```bash
# Apply changes immediately
source ~/.zshrc  # or ~/.bashrc for bash

# Then close and reopen your terminal

# Verify the setting
echo $ANTHROPIC_MODEL

# Or check in Claude Code
/status
```

### reset-project-workspaces.sh

Finds and deletes all `workspace.xml` files in IntelliJ IDEA projects. This is useful for cleaning up workspace-specific settings that can cause issues or conflicts when sharing projects or switching between different development environments.

#### Features

- **Recursive search**: Searches through nested project directories (configurable depth)
- **Safe operation**: Dry-run mode to preview changes before deleting
- **Colorful output**: Easy-to-read colored terminal output with clear status indicators
- **Detailed summary**: Shows comprehensive results with success/failure statistics
- **Configurable depth**: Control how deep to search for projects (default: 5 levels)

#### Usage

```bash
# Basic usage - search with default depth (5 levels)
./scripts/reset-project-workspaces.sh

# Preview what would be deleted (dry-run mode)
./scripts/reset-project-workspaces.sh --dry-run

# Search only 3 levels deep
./scripts/reset-project-workspaces.sh --depth 3

# Combine options
./scripts/reset-project-workspaces.sh --depth 7 --dry-run
```

#### Options

| Option | Description |
|--------|-------------|
| `-d, --depth N` | Set maximum search depth (default: 5) |
| `--dry-run` | Show what would be deleted without actually deleting |
| `-h, --help` | Show help message |

#### Why Delete workspace.xml?

The `workspace.xml` file in IntelliJ IDEA's `.idea` folder stores:
- Window layout and editor tabs
- Run configurations (local paths)
- Debugging session state
- Tool window states
- File-specific editor settings

These settings are user-specific and can cause issues when:
- Switching between different machines
- Collaborating with team members
- Dealing with corrupt workspace state
- Troubleshooting IDE performance issues

#### Example Output

```
╔════════════════════════════════════════════════════════════╗
║  IntelliJ IDEA Workspace Reset Tool                       ║
╚════════════════════════════════════════════════════════════╝

Scanning directory: /Users/username/IdeaProjects
Maximum depth: 5 levels

Searching for workspace.xml files...

[DELETED] private/local-scripts/.idea/workspace.xml
[DELETED] work/backend-api/.idea/workspace.xml
[DELETED] personal/demo-app/.idea/workspace.xml

╔════════════════════════════════════════════════════════════╗
║  Summary                                                   ║
╚════════════════════════════════════════════════════════════╝

Total workspace.xml files found: 3
Successfully deleted: 3

✓ All workspace files successfully deleted!
```

## Requirements

- macOS or Linux
- Bash 4.0+
- IntelliJ IDEA projects in `~/IdeaProjects` directory

## Contributing

Feel free to add more utility scripts to this collection. Please maintain:
- Clear documentation in this README
- Helpful command-line options
- Colorful, user-friendly output
- Safe defaults (e.g., dry-run options for destructive operations)

## License

MIT License - Feel free to use and modify as needed.