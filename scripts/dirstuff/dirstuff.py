#!/usr/bin/env python3

import os
import sys
import argparse

# --- Configuration ---

# 1. DIRECTORIES to ignore completely (The Tree won't even enter these).
#    I added 'google', 'logs', 'spliced', etc., based on your output.
SKIP_DIRS = {
    # Standard ignores
    'node_modules', '.git', '__pycache__', '.venv', 'venv', 'env', 
    '.idea', '.vscode', 'dist', 'build', 'target', '.lake', '.obsidian',
    
    # Specific to your project (Noise reduction)
    'google',          # Library folder
    'google.genai',    # Library folder
    'argparse',        # Library folder
    'sys',             # Library folder
    'logs',            # Log folder
    'locks',           # Lock folder
    'site-packages',
    'rmscene'
}

# 2. SPECIFIC FILES to ignore completely (even if they match the extension list)
SKIP_FILES = {
    'package-lock.json',
    'yarn.lock',
    '.DS_Store',
    'Thumbs.db',
    'times.json' # Looks like generated data
}

# 3. ALLOW LIST: Only files with these extensions will be processed.
#    Anything NOT in this list is skipped.
ALLOWED_EXTENSIONS = {
    # Code
    '.py', '.js', '.ts', '.c', '.cpp', '.h', '.java', '.go', '.rs', '.php', '.rb', '.m',
    # Web
    '.html', '.css', '.scss',
    # Config / Data (Readable)
    '.json', '.yaml', '.yml', '.toml', '.xml', '.ini',
    # Documentation
    '.md', '.txt', '.rst'
}

# 4. FILES WITHOUT EXTENSIONS that are allowed.
ALLOWED_NO_EXT_FILES = {
    'makefile', 
    'dockerfile', 
    'jenkinsfile',
    '.gitignore', 
    '.env',
    'license', 
    'readme',
    'changelog'
}

def is_allowed_file(filename):
    """
    Returns True ONLY if the file is in the whitelist.
    """
    # 1. Strict Skip List
    if filename in SKIP_FILES:
        return False

    name_lower = filename.lower()
    root, ext = os.path.splitext(filename)
    
    # 2. Handle files with NO extension (Makefile, Dockerfile)
    if not ext:
        return name_lower in ALLOWED_NO_EXT_FILES

    # 3. Handle files WITH extensions (Whitelist check)
    if ext.lower() in ALLOWED_EXTENSIONS:
        return True

    # If it didn't match the allowed list, skip it.
    return False


def is_dot_entry(name):
    return name.startswith(".") and name not in {".", ".."}


def print_tree(startpath, skip_dirs, showdot):
    """
    Prints directory tree, filtering out files that aren't allowed.
    """
    print(f"--- DIRECTORY TREE of '{startpath}' ---")
    print(startpath)
    
    def walk(directory, prefix=""):
        try:
            entries = sorted(os.listdir(directory))
        except OSError as e:
            print(f"{prefix}[Error reading directory: {e}]")
            return

        # Filter entries
        filtered_entries = []
        for e in entries:
            # Skip Directories defined in config
            if e in skip_dirs:
                continue
            if not showdot and is_dot_entry(e):
                continue
                
            full_path = os.path.join(directory, e)
            
            # If it's a file, ONLY show it if it matches our whitelist
            if os.path.isfile(full_path):
                if not is_allowed_file(e):
                    continue
            
            filtered_entries.append(e)
        
        entries_count = len(filtered_entries)
        for i, entry in enumerate(filtered_entries):
            path = os.path.join(directory, entry)
            is_last = (i == entries_count - 1)
            
            connector = "└── " if is_last else "├── "
            print(f"{prefix}{connector}{entry}")
            
            if os.path.isdir(path):
                extension = "    " if is_last else "│   "
                walk(path, prefix + extension)

    walk(startpath)
    print("-------------------------------------")
    print()


def process_files(target_dir, recursive, skip_dirs, showdot):
    """
    Iterates through files and prints contents ONLY if allowed.
    """
    
    if recursive:
        print(f"--- FILE CONTENTS (Recursive) ---")
        for root, dirs, files in os.walk(target_dir):
            # Prune skipped directories
            dirs[:] = [
                d for d in dirs
                if d not in skip_dirs and (showdot or not is_dot_entry(d))
            ]
            
            for file in sorted(files):
                if not showdot and is_dot_entry(file):
                    continue
                if is_allowed_file(file):
                    full_path = os.path.join(root, file)
                    print_file_content(full_path, target_dir)
    else:
        print("--- FILE CONTENTS (Top-Level Only) ---")
        try:
            for entry in sorted(os.listdir(target_dir)):
                if entry in skip_dirs:
                    continue
                if not showdot and is_dot_entry(entry):
                    continue

                full_path = os.path.join(target_dir, entry)
                if os.path.isfile(full_path) and is_allowed_file(entry):
                    print_file_content(full_path, target_dir)
        except OSError as e:
            print(f"Error accessing directory: {e}")
            sys.exit(1)


def print_file_content(filepath, root_dir):
    """
    Prints the content of a single file with headers. 
    """
    rel_path = os.path.relpath(filepath, root_dir)
    
    # Don't print this script itself
    if os.path.basename(filepath) == os.path.basename(sys.argv[0]):
        return

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        print()
        print("#" * 50)
        print(f"# START FILE: {rel_path}")
        print("#" * 50)
        print(content)
        print()
        print("#" * 50)
        print(f"# END FILE: {rel_path}")
        print("#" * 50)
        print()
        
    except UnicodeDecodeError:
        # Just in case a whitelisted file is actually binary
        print(f"[Skipped binary content in {rel_path}]")
    except Exception as e:
        print(f"[Error reading file {rel_path}: {e}]")


def main():
    parser = argparse.ArgumentParser(
        description="Display directory tree and code contents (Strict Whitelist Mode)."
    )
    parser.add_argument(
        "directory", 
        nargs="?", 
        default=".", 
        help="The directory to process (default: current directory)"
    )
    parser.add_argument(
        "-R", "--recursive", 
        action="store_true", 
        help="Recursively process files in all subdirectories"
    )
    parser.add_argument(
        "--showdot",
        action="store_true",
        help="Include dot-prefixed files and directories"
    )

    args = parser.parse_args()
    target_dir = args.directory

    if not os.path.isdir(target_dir):
        print(f"Error: Directory '{target_dir}' not found.")
        sys.exit(1)

    print_tree(target_dir, SKIP_DIRS, args.showdot)
    process_files(target_dir, args.recursive, SKIP_DIRS, args.showdot)

if __name__ == "__main__":
    main()
