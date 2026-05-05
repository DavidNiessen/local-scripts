#!/usr/bin/env bash

# Reset IntelliJ IDEA workspace.xml files
# This script finds and deletes all workspace.xml files in IntelliJ projects

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper function for colored output that works in both bash and sh
print_color() {
    printf "%b\n" "$1"
}

# Configuration
IDEA_PROJECTS_DIR="${HOME}/IdeaProjects"
MAX_DEPTH=5  # Default search depth
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--depth)
            MAX_DEPTH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            print_color "${BOLD}Usage:${NC} $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -d, --depth N    Set maximum search depth (default: 5)"
            echo "  --dry-run        Show what would be deleted without actually deleting"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --depth 3     # Search only 3 levels deep"
            echo "  $0 --dry-run     # Preview what would be deleted"
            exit 0
            ;;
        *)
            print_color "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Check if IdeaProjects directory exists
if [ ! -d "$IDEA_PROJECTS_DIR" ]; then
    print_color "${RED}Error: Directory $IDEA_PROJECTS_DIR does not exist${NC}"
    exit 1
fi

# Print header
echo ""
print_color "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
print_color "${CYAN}║${NC}  ${BOLD}IntelliJ IDEA Workspace Reset Tool${NC}                    ${CYAN}║${NC}"
print_color "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
print_color "${BLUE}Scanning directory:${NC} $IDEA_PROJECTS_DIR"
print_color "${BLUE}Maximum depth:${NC} $MAX_DEPTH levels"
if [ "$DRY_RUN" = true ]; then
    print_color "${YELLOW}Mode: DRY RUN (no files will be deleted)${NC}"
fi
echo ""

# Initialize counters
total_found=0
total_deleted=0
total_failed=0
declare -a deleted_files
declare -a failed_files

# Find and process workspace.xml files
print_color "${MAGENTA}Searching for workspace.xml files...${NC}"
echo ""

# Store find results to avoid process substitution issues with sh
workspace_files=$(find "$IDEA_PROJECTS_DIR" -maxdepth "$MAX_DEPTH" -type f -path "*/.idea/workspace.xml" 2>/dev/null)

if [ -n "$workspace_files" ]; then
    while IFS= read -r workspace_file; do
        ((total_found++))

        # Extract relative path for display
        relative_path="${workspace_file#"$IDEA_PROJECTS_DIR"/}"

        if [ "$DRY_RUN" = true ]; then
            print_color "${YELLOW}[WOULD DELETE]${NC} $relative_path"
            deleted_files+=("$relative_path")
            ((total_deleted++))
        else
            if rm "$workspace_file" 2>/dev/null; then
                print_color "${GREEN}[DELETED]${NC} $relative_path"
                deleted_files+=("$relative_path")
                ((total_deleted++))
            else
                print_color "${RED}[FAILED]${NC} $relative_path"
                failed_files+=("$relative_path")
                ((total_failed++))
            fi
        fi
    done <<< "$workspace_files"
fi

# Print summary
echo ""
print_color "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
print_color "${CYAN}║${NC}  ${BOLD}Summary${NC}                                                ${CYAN}║${NC}"
print_color "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    print_color "${BLUE}Total workspace.xml files found:${NC} ${BOLD}$total_found${NC}"
    print_color "${YELLOW}Files that would be deleted:${NC} ${BOLD}$total_deleted${NC}"
else
    print_color "${BLUE}Total workspace.xml files found:${NC} ${BOLD}$total_found${NC}"
    print_color "${GREEN}Successfully deleted:${NC} ${BOLD}$total_deleted${NC}"

    if [ $total_failed -gt 0 ]; then
        print_color "${RED}Failed to delete:${NC} ${BOLD}$total_failed${NC}"
    fi
fi

echo ""

# Show details if there were failures
if [ $total_failed -gt 0 ] && [ "$DRY_RUN" = false ]; then
    print_color "${RED}${BOLD}Failed deletions:${NC}"
    for file in "${failed_files[@]}"; do
        print_color "  ${RED}•${NC} $file"
    done
    echo ""
fi

# Final message
if [ $total_found -eq 0 ]; then
    print_color "${YELLOW}No workspace.xml files found.${NC}"
elif [ "$DRY_RUN" = true ]; then
    print_color "${YELLOW}Dry run complete. Use without --dry-run to actually delete files.${NC}"
elif [ $total_deleted -eq $total_found ]; then
    print_color "${GREEN}${BOLD}✓${NC} ${GREEN}All workspace files successfully deleted!${NC}"
elif [ $total_failed -gt 0 ]; then
    print_color "${RED}${BOLD}✗${NC} ${RED}Some files could not be deleted. Check permissions.${NC}"
else
    print_color "${GREEN}${BOLD}✓${NC} ${GREEN}Operation completed successfully!${NC}"
fi

echo ""

exit 0