#!/usr/bin/env bash

# normalize-audio-files.sh
#
# Renames audio files using the TITLE tag.
#
# Supports:
#   mp3, flac, aiff, wav
#
# Usage:
#
#   ./normalize-audio-files.sh
#       Prompt for file/folder and whether to repair FLAC artwork.
#
#   ./normalize-audio-files.sh "/music"
#       Process file/folder without prompting. No FLAC repair.
#
#   ./normalize-audio-files.sh "/music" --repair
#   ./normalize-audio-files.sh "/music" -r
#       Process file/folder and repair FLAC artwork.

set -u

# ---------- dependency checks ----------

for cmd in ffprobe ffmpeg; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: '$cmd' not found."
        echo "Install ffmpeg from: https://ffmpeg.org/download.html"
        exit 1
    fi
done

# ---------- argument parsing ----------

repair_flac=false
input=""

case $# in

    # No args -> prompt for everything
    0)
        read -rp "Folder or file to scan (Enter = current directory): " input
        input="${input:-$(pwd)}"
        input="${input//\\//}"

        read -rp "Repair FLAC artwork metadata? [y/N] " ans
        ans="$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')"

        [[ "$ans" == "y" ]] && repair_flac=true
        ;;

    # One arg -> path only, no prompts
    1)
        input="$1"
        input="${input//\\//}"
        ;;

    # Two args -> path + repair flag
    2)
        input="$1"
        input="${input//\\//}"

        case "$2" in
            --repair|-r)
                repair_flac=true
                ;;
            *)
                echo "Usage:"
                echo "  ./normalize-audio-files.sh"
                echo "  ./normalize-audio-files.sh <file-or-folder>"
                echo "  ./normalize-audio-files.sh <file-or-folder> --repair"
                echo "  ./normalize-audio-files.sh <file-or-folder> -r"
                exit 1
                ;;
        esac
        ;;

    *)
        echo "Usage:"
        echo "  ./normalize-audio-files.sh"
        echo "  ./normalize-audio-files.sh <file-or-folder>"
        echo "  ./normalize-audio-files.sh <file-or-folder> --repair"
        echo "  ./normalize-audio-files.sh <file-or-folder> -r"
        exit 1
        ;;
esac

input="${input%/}"

# ---------- validate input ----------

if [[ -d "$input" ]]; then
    mode="dir"
    target_dir="$input"

elif [[ -f "$input" ]]; then
    mode="file"
    target_file="$input"

else
    echo "Error: '$input' does not exist."
    exit 1
fi

echo

if [[ "$mode" == "dir" ]]; then
    echo "Scanning folder: $target_dir"
else
    echo "Scanning file: $(basename "$target_file")"
fi

echo "FLAC artwork repair: $repair_flac"
echo

# ---------- helper functions ----------

sanitize_title() {
    local t="$1"

    t="$(printf '%s' "$t" |
        tr -d '\\/:"*?<>|' |
        sed 's/^[[:space:].]*//;s/[[:space:].]*$//')"

    printf '%s' "$t"
}

lowercase_ext() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

has_embedded_artwork() {
    local file="$1"

    ffprobe -v error \
        -select_streams v:0 \
        -show_entries stream=index \
        -of csv=p=0 \
        "$file" 2>/dev/null | grep -q .
}

rewrite_flac_metadata() {
    local file="$1"
    local tmp="${file}.repair.$$.flac"
    local cover="${file}.cover.$$.jpg"

    echo "  Repairing FLAC metadata: $(basename "$file")"

    # Try extracting artwork
    ffmpeg -v error -y \
        -i "$file" \
        -an \
        -map 0:v:0 \
        "$cover" >/dev/null 2>&1

    if [[ -f "$cover" ]]; then

        # Rebuild audio and recreate artwork block
        if ffmpeg -v error -y \
            -i "$file" \
            -i "$cover" \
            -map 0:a \
            -map 1:v \
            -map_metadata 0 \
            -c:a flac \
            -c:v mjpeg \
            -disposition:v attached_pic \
            -f flac \
            "$tmp"; then

            rm -f -- "$cover"
            mv -f -- "$tmp" "$file"
            return 0
        fi

    else

        # No artwork found
        if ffmpeg -v error -y \
            -i "$file" \
            -map 0:a \
            -map_metadata 0 \
            -c:a flac \
            -f flac \
            "$tmp"; then

            mv -f -- "$tmp" "$file"
            return 0
        fi
    fi

    rm -f -- "$cover" "$tmp"
    return 1
}

# ---------- build file list ----------

declare -a files=()

if [[ "$mode" == "dir" ]]; then

    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(
        find "$target_dir" -maxdepth 1 -type f \
            \( -iname "*.mp3" \
            -o -iname "*.flac" \
            -o -iname "*.aiff" \
            -o -iname "*.wav" \) \
            -print0 | sort -z
    )

else

    ext="${target_file##*.}"
    ext_lc="$(lowercase_ext "$ext")"

    case "$ext_lc" in
        mp3|flac|aiff|wav)
            files+=("$target_file")
            ;;
        *)
            echo "Unsupported file type:"
            echo "  $target_file"
            exit 1
            ;;
    esac

fi

# ---------- collect rename operations ----------

declare -a src=()
declare -a dst=()
declare -a skips=()

for file in "${files[@]}"; do

    base="$(basename "$file")"
    ext="${base##*.}"
    ext_lc="$(lowercase_ext "$ext")"

    # Optional FLAC repair

    if [[ "$repair_flac" == true && "$ext_lc" == "flac" ]]; then
        if has_embedded_artwork "$file"; then
            if ! rewrite_flac_metadata "$file"; then
                skips+=("  metadata repair failed : $base")
                continue
            fi
        fi
    fi

    # Read title tag

    title="$(ffprobe -v quiet \
        -show_entries format_tags=title \
        -of default=noprint_wrappers=1:nokey=1 \
        "$file" 2>/dev/null | head -1)"

    if [[ -z "$title" ]]; then
        skips+=("  no title metadata  : $base")
        continue
    fi

    safe="$(sanitize_title "$title")"

    if [[ -z "$safe" ]]; then
        skips+=("  title unusable      : $base (title: '$title')")
        continue
    fi

    new_name="${safe}.${ext_lc}"
    new_path="$(dirname "$file")/$new_name"

    if [[ "$file" == "$new_path" ]]; then
        skips+=("  already correct     : $base")
        continue
    fi

    src+=("$file")
    dst+=("$new_path")

done

# ---------- nothing to do ----------

if [[ ${#src[@]} -eq 0 ]]; then

    if [[ ${#skips[@]} -gt 0 ]]; then
        echo "Skipped:"
        printf '%s\n' "${skips[@]}"
        echo
    fi

    echo "No files to rename."
    exit 0
fi

# ---------- review ----------

echo "Proposed renames:"
echo "------------------------------------------------------------"

for i in "${!src[@]}"; do
    printf '  %-40s -> %s\n' \
        "$(basename "${src[$i]}")" \
        "$(basename "${dst[$i]}")"
done

echo

if [[ ${#skips[@]} -gt 0 ]]; then
    echo "Skipped:"
    printf '%s\n' "${skips[@]}"
    echo
fi

# ---------- conflict warnings ----------

has_conflict=false

for i in "${!dst[@]}"; do

    target="${dst[$i]}"

    for j in "${!dst[@]}"; do
        if [[ $i -ne $j && "${dst[$j]}" == "$target" ]]; then
            echo "WARNING: Multiple files would be renamed to:"
            echo "  $(basename "$target")"
            has_conflict=true
        fi
    done

    if [[ -f "$target" ]]; then

        is_rename_src=false

        for j in "${!src[@]}"; do
            if [[ "${src[$j]}" == "$target" ]]; then
                is_rename_src=true
                break
            fi
        done

        if [[ "$is_rename_src" == false ]]; then
            echo "WARNING: Would overwrite existing file:"
            echo "  $(basename "$target")"
            has_conflict=true
        fi
    fi

done

[[ "$has_conflict" == true ]] && echo

# ---------- approval ----------

read -rp "Apply ${#src[@]} rename(s)? [y/N] " confirm

confirm="$(printf '%s' "$confirm" | tr '[:upper:]' '[:lower:]')"

if [[ "$confirm" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

# ---------- rename ----------

ok=0
fail=0

echo

for i in "${!src[@]}"; do

    old_base="$(basename "${src[$i]}")"
    new_base="$(basename "${dst[$i]}")"

    if mv -- "${src[$i]}" "${dst[$i]}"; then
        printf '  OK      %-40s -> %s\n' \
            "$old_base" "$new_base"
        ((ok++))
    else
        printf '  FAILED  %s\n' "$old_base"
        ((fail++))
    fi

done

echo

if [[ $fail -eq 0 ]]; then
    echo "Done. $ok file(s) renamed."
else
    echo "Done with errors: $ok renamed, $fail failed."
    exit 1
fi
