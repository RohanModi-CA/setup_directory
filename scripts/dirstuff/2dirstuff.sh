#!/bin/bash

# A script to display a directory tree and the contents of its files.

# --- Usage function ---
# Prints help information and exits.
usage() {
  echo "Usage: $0 [-R] [directory_path]"
  echo
  echo "Description:"
  echo "  This script provides a comprehensive view of a directory's structure"
  echo "  and the content of its files."
  echo
  echo "Arguments:"
  echo "  -R              : Recursively process files in all subdirectories."
  echo "  directory_path  : The directory to process (default: current directory)."
  exit 1
}

# --- Check for dependencies ---
# Ensure the 'tree' command is available.
if ! command -v tree &> /dev/null; then
    echo "Error: 'tree' command not found." >&2
    echo "Please install it to use this script." >&2
    echo "  On Debian/Ubuntu: sudo apt-get install tree" >&2
    echo "  On CentOS/RHEL:   sudo yum install tree" >&2
    echo "  On macOS (Homebrew): brew install tree" >&2
    exit 1
fi

# --- Option Parsing ---
# Use getopts to handle the -R flag.
RECURSIVE=0
while getopts "Rh" opt; do
  case $opt in
    R)
      RECURSIVE=1
      ;;
    h)
      usage
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done
shift $((OPTIND-1)) # Remove parsed options from the argument list.

# --- Determine Target Directory ---
# Use the first remaining argument as the directory, or "." if none is provided.
if [ "$#" -gt 1 ]; then
    echo "Error: Too many arguments." >&2
    usage
fi
TARGET_DIR="${1:-.}" # If $1 is not set, default to "."

# Check if the target directory exists and is actually a directory.
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory '$TARGET_DIR' not found." >&2
  exit 1
fi

# --- Main Processing ---
# We run the core logic in a subshell `(...)` to avoid changing the
# current directory of the user's shell. This is a good practice.
(
  # Change to the target directory. Exit if it fails (e.g., permissions).
  cd "$TARGET_DIR" || exit 1

  # 1.) Print the directory tree.
  echo "--- DIRECTORY TREE of '$TARGET_DIR' ---"
  tree
  echo "-------------------------------------"
  echo

  # Prepare global options for the `find` command based on the -R flag.
  FIND_OPTIONS=()
  if [ "$RECURSIVE" -eq 1 ]; then
    echo "--- FILE CONTENTS (Recursive) ---"
    # No extra options needed; find searches recursively by default.
  else
    echo "--- FILE CONTENTS (Top-Level Only) ---"
    # Limit find to the current directory only. This is a "global option".
    FIND_OPTIONS+=("-maxdepth" "1")
  fi

  # 2.) Find and process files.
  # The proper order is: find [path] [options] [tests] [actions]
  # Using `find ... -print0 | while read -r -d ''` is the safest way to
  # handle filenames that contain spaces, newlines, or other special characters.
  find . "${FIND_OPTIONS[@]}" -type f -print0 | while IFS= read -r -d '' file; do
    # Remove the leading './' from find's output for a cleaner path.
    relative_path="${file#./}"

    echo
    echo "##################################################"
    echo "# START FILE: ${relative_path}"
    echo "##################################################"
    
    # Use cat to print the file's content.
    cat "${relative_path}"
    
    echo
    echo "##################################################"
    echo "# END FILE: ${relative_path}"
    echo "##################################################"
    echo
  done
)
