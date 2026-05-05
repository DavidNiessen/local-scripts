res# Local Scripts Collection

A collection of utility scripts for managing local development environment and IntelliJ IDEA projects.

## Scripts

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

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd local-scripts
```

2. Make scripts executable:
```bash
chmod +x scripts/*.sh
```

3. (Optional) Add scripts to your PATH:
```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$PATH:/Users/username/IdeaProjects/private/local-scripts/scripts"
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