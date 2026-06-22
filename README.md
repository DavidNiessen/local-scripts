## Local Scripts Collection

A collection of utility scripts for managing local development environments, audio plugin paths, audio file metadata, and IntelliJ IDEA projects.

## Installation

### Quick Install (Recommended)

Run the installer to make all scripts available globally:

```bash
./install.sh
```

This will:

* Create `~/.local/bin` if it doesn't exist
* Symlink all scripts to `~/.local/bin`
* Optionally add `~/.local/bin` to your PATH
* Allow you to run scripts from anywhere without the `.sh` extension

After installation, you can run scripts from anywhere:

```bash
global-claude-code-model.sh claude-opus-4-7
normalize-audio-files.sh
reset-project-workspaces.sh --dry-run
setup-vst3-redirect.sh
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

* **Cross-platform**: Works on both Linux and macOS
* **Auto-detection**: Automatically detects shell type (bash/zsh) and config file
* **Safe updates**: Creates backup before modifying existing configuration
* **Clear instructions**: Provides step-by-step guidance for applying changes

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
2. Adds or updates `export ANTHROPIC_MODEL="<model-name>"` in your shell config file (`~/.zshrc` or `~/.bashrc`)
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

---

### normalize-audio-files.sh

Renames audio files in a folder using the track title stored in their metadata tags.

Optionally, the script can rebuild FLAC files containing embedded artwork to repair malformed metadata blocks that may cause issues in some DJ software.

#### Features

* **Metadata-driven**: Reads the `title` tag via `ffprobe` (supports mp3, flac, aiff, wav)
* **Optional FLAC repair**: Can rebuild FLAC metadata and recreate embedded artwork blocks
* **Single file or folder support**: Process either an individual audio file or an entire folder
* **Review before rename**: Displays a full preview of all proposed renames and requires explicit approval
* **Conflict detection**: Warns if two files would be renamed to the same name, or if a rename would overwrite an existing file
* **Safe filenames**: Strips characters that are invalid on Windows (`\ / : * ? " < > |`)
* **Cross-platform**: Works on macOS, Linux, and Windows (Git Bash)

#### Requirements

Both `ffprobe` and `ffmpeg`, which ship with FFmpeg:

```bash
# macOS
brew install ffmpeg

# Windows
winget install ffmpeg

# Debian/Ubuntu
apt install ffmpeg
```

#### Usage

```bash
# Prompt for file/folder and whether to repair FLAC metadata
normalize-audio-files.sh

# Process a folder without prompts
normalize-audio-files.sh "/Volumes/Music/Albums"

# Process a single file without prompts
normalize-audio-files.sh "/Volumes/Music/track.flac"

# Process and also repair FLAC artwork metadata
normalize-audio-files.sh "/Volumes/Music/Albums" --repair

# Short form
normalize-audio-files.sh "/Volumes/Music/Albums" -r
```

#### Example session

```text
Folder or file to scan (Enter = current directory): /Volumes/Music/Albums/Daft Punk
Repair FLAC artwork metadata? [y/N] y

Scanning folder: /Volumes/Music/Albums/Daft Punk
FLAC artwork repair: true

Proposed renames:
------------------------------------------------------------
  track01.mp3                        -> One More Time.mp3
  track02.mp3                        -> Aerodynamic.mp3
  track03.flac                       -> Digital Love.flac

Skipped:
  already correct     : Harder Better Faster Stronger.mp3

Apply 3 rename(s)? [y/N] y

  OK      track01.mp3               -> One More Time.mp3
  OK      track02.mp3               -> Aerodynamic.mp3
  OK      track03.flac              -> Digital Love.flac

Done. 3 file(s) renamed.
```

#### FLAC Metadata Repair

When enabled, the script:

1. Detects FLAC files containing embedded artwork.
2. Extracts the artwork.
3. Rebuilds the FLAC file.
4. Re-embeds the artwork.

This can repair malformed FLAC metadata blocks that cause errors in some DJ applications.

The repair step:

* Only affects `.flac` files
* Preserves audio quality (FLAC is lossless)
* Preserves standard metadata tags such as title, artist, album, and date
* Is only performed when explicitly enabled

---

### setup-vst3-redirect.sh

Creates a symbolic link for the standard VST3 plugin directory, allowing you to store your VST3 plugins in a custom location while keeping DAWs such as Ableton Live and FL Studio compatible.

#### Features

* **Cross-platform**: Supports Linux, macOS, and Windows (Git Bash/MSYS2/Cygwin)
* **DAW compatible**: Uses the standard VST3 directories recognized by Ableton Live, FL Studio, and most other VST3 hosts
* **Safe operation**: Refuses to overwrite existing VST3 directories
* **Interactive setup**: Prompts for the desired plugin storage location
* **Absolute paths**: Resolves and stores the target directory as an absolute path

#### Usage

```bash
# Run from anywhere (after installation)
setup-vst3-redirect.sh

# Or directly
./scripts/setup-vst3-redirect.sh
```

#### Platform-Specific VST3 Locations

| Platform | VST3 Directory                       |
| -------- | ------------------------------------ |
| Linux    | `~/.vst3`                            |
| macOS    | `/Library/Audio/Plug-Ins/VST3`       |
| Windows  | `C:\Program Files\Common Files\VST3` |

#### What it does

1. Detects the current operating system.
2. Determines the standard VST3 plugin directory.
3. Checks whether the VST3 directory already exists.
4. Prompts for a target directory where VST3 plugins should be stored.
5. Validates that the target directory exists.
6. Creates a symbolic link from the standard VST3 location to the target directory.

#### Example

Suppose you want all VST3 plugins stored on an external SSD:

```text
External SSD/
└── Audio/
    └── VST3/
```

Running:

```bash
setup-vst3-redirect.sh
```

and providing:

```text
/Volumes/ExternalSSD/Audio/VST3
```

will create:

```text
/Library/Audio/Plug-Ins/VST3 -> /Volumes/ExternalSSD/Audio/VST3
```

on macOS, or the equivalent location on Linux/Windows.

#### Requirements

##### Linux

No special permissions are required when creating `~/.vst3`.

##### macOS

The system-wide VST3 directory is located under `/Library`, so the script must be run with administrator privileges:

```bash
sudo setup-vst3-redirect.sh
```

##### Windows

The standard VST3 directory is located under `Program Files`, so the script should be run from an Administrator shell (Git Bash, MSYS2, or Cygwin).

#### Safety Notes

The script intentionally refuses to proceed if the standard VST3 directory already exists:

```text
WARNING: '/Library/Audio/Plug-Ins/VST3' already exists.
No changes have been made.
```

This prevents accidentally overwriting an existing plugin installation. If you want to use a redirect, manually back up or remove the existing VST3 directory before running the script.

---

### reset-project-workspaces.sh

Finds and deletes all `workspace.xml` files in IntelliJ IDEA projects. This is useful for cleaning up workspace-specific settings that can cause issues or conflicts when sharing projects or switching between different development environments.

#### Features

* **Recursive search**: Searches through nested project directories (configurable depth)
* **Safe operation**: Dry-run mode to preview changes before deleting
* **Colorful output**: Easy-to-read colored terminal output with clear status indicators
* **Detailed summary**: Shows comprehensive results with success/failure statistics
* **Configurable depth**: Control how deep to search for projects (default: 5 levels)

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

| Option          | Description                                          |
| --------------- | ---------------------------------------------------- |
| `-d, --depth N` | Set maximum search depth (default: 5)                |
| `--dry-run`     | Show what would be deleted without actually deleting |
| `-h, --help`    | Show help message                                    |

#### Why Delete workspace.xml?

The `workspace.xml` file in IntelliJ IDEA's `.idea` folder stores:

* Window layout and editor tabs
* Run configurations (local paths)
* Debugging session state
* Tool window states
* File-specific editor settings

These settings are user-specific and can cause issues when:

* Switching between different machines
* Collaborating with team members
* Dealing with corrupt workspace state
* Troubleshooting IDE performance issues

#### Example Output

```text
╔════════════════════════════════════════════════════════════╗
║  IntelliJ IDEA Workspace Reset Tool                      ║
╚════════════════════════════════════════════════════════════╝

Scanning directory: /Users/username/IdeaProjects
Maximum depth: 5 levels

Searching for workspace.xml files...

[DELETED] private/local-scripts/.idea/workspace.xml
[DELETED] work/backend-api/.idea/workspace.xml
[DELETED] personal/demo-app/.idea/workspace.xml

╔════════════════════════════════════════════════════════════╗
║  Summary                                                  ║
╚════════════════════════════════════════════════════════════╝

Total workspace.xml files found: 3
Successfully deleted: 3

✓ All workspace files successfully deleted!
```

## Requirements

* macOS, Linux, or Windows
* Bash 4.0+
* Git Bash, MSYS2, or Cygwin (Windows only)
* `ffprobe` / `ffmpeg` — required by `normalize-audio-files.sh`
* Administrator privileges on macOS and Windows when modifying system-wide VST3 directories
* IntelliJ IDEA projects in `~/IdeaProjects` directory (for `reset-project-workspaces.sh`)

## Contributing

Feel free to add more utility scripts to this collection. Please maintain:

* Clear documentation in this README
* Helpful command-line options
* Colorful, user-friendly output
* Safe defaults (e.g., dry-run options for destructive operations)

## License

MIT License — Feel free to use and modify as needed.
