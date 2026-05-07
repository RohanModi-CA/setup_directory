#!/bin/bash

# --- Configuration ---
# Set this to true to replace YouTube links with a placeholder.
# Set this to false to leave file contents exactly as they are.
REMOVE_YOUTUBE_LINKS=true

# --- Usage function ---
usage() {
  echo "Usage: $0 [-R] [directory_path]"
  echo
  echo "Description:"
  echo "  This script provides a comprehensive view of a directory's structure"
  echo "  and the content of its files. The files are printed in a specific order:"
  echo "  1. All files within any subdirectory named 'Reports' are printed first."
  echo "  2. All other files are printed second."
  echo "  Within each of these two groups, files are sorted by their last"
  echo "  modification time, from oldest to newest."
  echo
  echo "Arguments:"
  echo "  -R              : Recursively process files in all subdirectories."
  echo "  directory_path  : The directory to process (default: current directory)."
  exit 1
}

# --- Check for dependencies ---
if ! command -v tree &> /dev/null; then
    echo "Error: 'tree' command not found." >&2
    echo "Please install it to use this script." >&2
    exit 1
fi

# --- Option Parsing ---
RECURSIVE=0
while getopts "Rh" opt; do
  case $opt in
    R) RECURSIVE=1 ;;
    h) usage ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND-1))

# --- Determine Target Directory ---
if [ "$#" -gt 1 ]; then
    echo "Error: Too many arguments." >&2
    usage
fi
TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory '$TARGET_DIR' not found." >&2
  exit 1
fi

# --- Main Processing ---
(
  cd "$TARGET_DIR" || exit 1

  # --- NEW: Print Today's Date ---
  # Format: Weekday, Day, Month, Year (e.g., Monday, 27 October 2025)
  echo "For reference, today's date is: $(date '+%A, %d %B %Y')"
  echo

  # 1.) Print the directory tree.
  echo "--- DIRECTORY TREE of '$(pwd)' ---"
  tree
  echo "-------------------------------------"
  echo

  # Prepare global options for find
  FIND_OPTIONS=()
  if [ "$RECURSIVE" -eq 1 ]; then
    echo "--- FILE CONTENTS (Recursive, Sorted) ---"
  else
    echo "--- FILE CONTENTS (Top-Level Only, Sorted) ---"
    FIND_OPTIONS+=("-maxdepth" "1")
  fi

  # 2.) Collect file data
  file_data_to_sort=""
  while IFS= read -r -d '' file_path; do
    # Get last modification time as a Unix epoch timestamp
    # Note: stat -c %Y is GNU syntax. 
    mod_time=$(stat -c %Y "$file_path")

    priority=1
    if [[ "$file_path" =~ (^|/)Reports/ ]]; then
      priority=0
    fi
    
    file_data_to_sort+="${priority}\t${mod_time}\t${file_path}"$'\n'
    
  done < <(find . "${FIND_OPTIONS[@]}" -type f -print0)

  # 3.) Sort data and print contents
  if [[ -n "$file_data_to_sort" ]]; then
    while IFS=$'\t' read -r priority_code mod_time file_path; do
      if [[ -z "$file_path" ]]; then continue; fi

      # --- NEW: Format the modification date for display ---
      # We attempt to detect if we are on Linux (GNU date) or macOS (BSD date)
      # Format: Short Weekday MM/DD/YY (e.g., Wed 11/27/25)
      if date --version >/dev/null 2>&1; then
          # GNU Date (Linux)
          display_date=$(date -d "@$mod_time" "+%a %m/%d/%y")
      else
          # BSD Date (macOS)
          display_date=$(date -r "$mod_time" "+%a %m/%d/%y")
      fi

      relative_path="${file_path#./}"

      echo
      echo "=================================================="
      # --- UPDATED: Added Last Modified date to header ---
      echo "===== START FILE: ${relative_path} (Last Modified: ${display_date})"
      echo "=================================================="
      
      # --- UPDATED: Logic to remove YouTube links if enabled ---
      if [ "$REMOVE_YOUTUBE_LINKS" = true ]; then
        # Fixed: Used '~' as delimiter to avoid conflict with regex OR operator '|'
        sed -E 's~https?://(www\.)?(youtube\.com|youtu\.be)/[^[:space:]]*~[YOUTUBE LINK REMOVED]~g' "${relative_path}"
      else
        cat "${relative_path}"
      fi
      
      echo
      echo "=================================================="
      echo "===== END FILE: ${relative_path}"
      echo "=================================================="
      echo

    done < <(echo -e "$file_data_to_sort" | sort -s -n -k1,1 -k2,2)
  fi
)
