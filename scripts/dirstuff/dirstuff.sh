#!/bin/bash

# --- Configuration ---
# List of directory names to skip during recursive search.
# Initialize with 'node_modules'. 
SKIP_DIRS=("node_modules")

# --- Usage function ---
usage() {
  echo "Usage: $0 [-R] [directory_path]"
  echo
  echo "Description:"
  echo "  This script provides a comprehensive view of a directory's structure"
  echo "  and the content of its files."
  echo "  Ignored directories: ${SKIP_DIRS[*]}"
  echo
  echo "Arguments:"
  echo "  -R              : Recursively process files in all subdirectories."
  echo "  directory_path  : The directory to process (default: current directory)."
  exit 1
}

# --- Check for dependencies ---
if ! command -v tree &> /dev/null; then
    echo "Error: 'tree' command not found." >&2
    echo "Please install it: sudo apt-get install tree (or brew install tree)" >&2
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

  # 1.) Print the directory tree.
  echo "--- DIRECTORY TREE of '$TARGET_DIR' ---"
  
  # Prepare ignore pattern for tree (format: "dir1|dir2")
  TREE_IGNORE=""
  if [ ${#SKIP_DIRS[@]} -gt 0 ]; then
      TREE_IGNORE=$(IFS='|'; echo "${SKIP_DIRS[*]}")
  fi
  
  if [ -n "$TREE_IGNORE" ]; then
      tree -I "$TREE_IGNORE"
  else
      tree
  fi
  
  echo "-------------------------------------"
  echo

  # 2.) Build the Find Command
  FIND_CMD=("find" ".")

  # A. Handle Max Depth
  if [ "$RECURSIVE" -eq 0 ]; then
    echo "--- FILE CONTENTS (Top-Level Only) ---"
    FIND_CMD+=("-maxdepth" "1")
  else
    echo "--- FILE CONTENTS (Recursive, skipping: ${SKIP_DIRS[*]}) ---"
  fi

  # B. Handle Exclusions (Pruning)
  # FIX: We use "(" and ")" instead of "\(" and "\)".
  # The array preserves the characters safely; we don't want to pass a literal '\' to find.
  if [ ${#SKIP_DIRS[@]} -gt 0 ]; then
      FIND_CMD+=("(")
      for i in "${!SKIP_DIRS[@]}"; do
          if [ "$i" -gt 0 ]; then
              FIND_CMD+=("-o")
          fi
          FIND_CMD+=("-name" "${SKIP_DIRS[$i]}")
      done
      FIND_CMD+=(")" "-prune" "-o")
  fi

  # C. Final Actions
  FIND_CMD+=("-type" "f" "-print0")

  # 3.) Execute Find
  "${FIND_CMD[@]}" | while IFS= read -r -d '' file; do
    relative_path="${file#./}"

    echo
    echo "##################################################"
    echo "# START FILE: ${relative_path}"
    echo "##################################################"
    
    cat "${relative_path}"
    
    echo
    echo "##################################################"
    echo "# END FILE: ${relative_path}"
    echo "##################################################"
    echo
  done
)
