#!/bin/bash

# Check if the directory is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

TARGET_DIR=$1

# Find all directories under the target directory
find "$TARGET_DIR" -type d | sort -r | while read -r dir; do
    # Check if facets.yaml exists in the directory
    if [ ! -f "$dir/facets.yaml" ]; then
        # Attempt to delete the directory if it's empty
        if rmdir "$dir" 2>/dev/null; then
            echo "Deleted empty directory: $dir"
        else
            echo "Directory $dir is not empty. Skipping."
        fi
    else
        echo "Directory $dir contains facets.yaml. Skipping."
    fi
done

# Function to recursively delete empty parent directories
cleanup_empty_parents() {
    local dir="$1"
    while [ "$dir" != "$TARGET_DIR" ]; do
        parent_dir=$(dirname "$dir")
        if [ -z "$(ls -A "$parent_dir")" ]; then
            if rmdir "$parent_dir" 2>/dev/null; then
                echo "Deleted empty parent directory: $parent_dir"
            fi
        fi
        dir="$parent_dir"
    done
}

# Cleanup empty parent directories after processing
find "$TARGET_DIR" -type d | sort -r | while read -r dir; do
    if [ -z "$(ls -A "$dir")" ]; then
        cleanup_empty_parents "$dir"
    fi
done