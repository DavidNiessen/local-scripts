#!/usr/bin/env bash

# Renames audio files using the title stored in their metadata.
# Supports: mp3, flac, aiff, wav
# Requires: ffprobe (part of ffmpeg)

if ! command -v ffprobe &>/dev/null; then
    echo "Error: ffprobe not found. Install ffmpeg: https://ffmpeg.org/download.html"
    exit 1
fi

# ---------- folder selection ----------

read -rp "Folder to scan (press Enter for current directory): " folder
folder="${folder:-$(pwd)}"
folder="${folder//\\//}"          # Git Bash on Windows: backslash → forward slash
folder="${folder%/}"              # strip trailing slash

if [[ ! -d "$folder" ]]; then
    echo "Error: '$folder' is not a directory."
    exit 1
fi

echo ""
echo "Scanning: $folder"
echo ""

# ---------- collect files ----------

declare -a src=()
declare -a dst=()
declare -a skips=()

sanitize_title() {
    # Strip chars invalid on Windows (and problematic on any OS), trim edge whitespace/dots
    local t="$1"
    t="$(printf '%s' "$t" | tr -d '\\/:"*?<>|' | sed 's/^[[:space:].]*//;s/[[:space:].]*$//')"
    printf '%s' "$t"
}

lowercase_ext() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

while IFS= read -r -d '' file; do
    base="$(basename "$file")"
    ext="${base##*.}"
    ext_lc="$(lowercase_ext "$ext")"

    title="$(ffprobe -v quiet -show_entries format_tags=title \
        -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | head -1)"

    if [[ -z "$title" ]]; then
        skips+=("  no title metadata  : $base")
        continue
    fi

    safe="$(sanitize_title "$title")"
    if [[ -z "$safe" ]]; then
        skips+=("  title unusable      : $base  (title: '$title')")
        continue
    fi

    new_name="${safe}.${ext_lc}"
    new_path="$(dirname "$file")/${new_name}"

    if [[ "$file" == "$new_path" ]]; then
        skips+=("  already correct     : $base")
        continue
    fi

    src+=("$file")
    dst+=("$new_path")
done < <(find "$folder" -maxdepth 1 -type f \
    \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.aiff" -o -iname "*.wav" \) \
    -print0 | sort -z)

# ---------- nothing to do ----------

if [[ ${#src[@]} -eq 0 ]]; then
    if [[ ${#skips[@]} -gt 0 ]]; then
        echo "Skipped (no action needed):"
        printf '%s\n' "${skips[@]}"
        echo ""
    fi
    echo "No files to rename."
    exit 0
fi

# ---------- review ----------

echo "Proposed renames:"
echo "─────────────────────────────────────────────────────────────────────"
for i in "${!src[@]}"; do
    printf '  %-40s  →  %s\n' "$(basename "${src[$i]}")" "$(basename "${dst[$i]}")"
done
echo ""

if [[ ${#skips[@]} -gt 0 ]]; then
    echo "Skipped:"
    printf '%s\n' "${skips[@]}"
    echo ""
fi

# ---------- conflict warnings ----------

has_conflict=false
for i in "${!dst[@]}"; do
    target="${dst[$i]}"
    # two renames converge on the same name
    for j in "${!dst[@]}"; do
        if [[ $i -ne $j && "${dst[$j]}" == "$target" ]]; then
            echo "WARNING: Multiple files would be renamed to the same name: $(basename "$target")"
            has_conflict=true
        fi
    done
    # would overwrite an existing file that is NOT one of the files being renamed
    if [[ -f "$target" ]]; then
        is_rename_src=false
        for j in "${!src[@]}"; do
            [[ "${src[$j]}" == "$target" ]] && { is_rename_src=true; break; }
        done
        if [[ "$is_rename_src" == false ]]; then
            echo "WARNING: Would overwrite existing file: $(basename "$target")"
            has_conflict=true
        fi
    fi
done
[[ "$has_conflict" == true ]] && echo ""

# ---------- approval ----------

read -rp "Apply ${#src[@]} rename(s)? [y/N] " confirm
if [[ "$(printf '%s' "$confirm" | tr '[:upper:]' '[:lower:]')" != "y" ]]; then
    echo "Aborted. No files were changed."
    exit 0
fi

# ---------- rename ----------

echo ""
ok=0
fail=0
for i in "${!src[@]}"; do
    old_base="$(basename "${src[$i]}")"
    new_base="$(basename "${dst[$i]}")"
    if mv -- "${src[$i]}" "${dst[$i]}"; then
        printf '  OK      %-40s  →  %s\n' "$old_base" "$new_base"
        ((ok++))
    else
        printf '  FAILED  %s\n' "$old_base"
        ((fail++))
    fi
done

echo ""
if [[ $fail -eq 0 ]]; then
    echo "Done. $ok file(s) renamed."
else
    echo "Done with errors: $ok renamed, $fail failed."
    exit 1
fi
