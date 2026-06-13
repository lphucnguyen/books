#!/bin/bash
set -e
cd "$(dirname "$0")"

# Process each image file that contains .pdf-
while IFS= read -r img; do
    dir=$(dirname "$img")
    base=$(basename "$img")
    newbase=$(echo "$base" | sed 's/\.pdf-/-/g')
    if [[ "$base" != "$newbase" ]]; then
        new="$dir/$newbase"
        echo "Processing $img -> $new"
        # Update references in markdown files
        grep -rl "$base" . --include="*.md" | while read -r mdfile; do
            # Use empty string for -i on macOS
            sed -i '' "s|$base|$newbase|g" "$mdfile"
        done
        # Rename the file
        if [[ -e "$img" && ! -e "$new" ]]; then
            mv "$img" "$new"
            echo "  Renamed"
        else
            echo "  Skipping (target exists or source missing)"
        fi
    fi
done < <(find . -path "*/images/*" -type f -name "*.png")

echo "Done."
