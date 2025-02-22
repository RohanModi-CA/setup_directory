#!/usr/bin/env bash

# ==== SAMPLE USAGE ===
# run.sh "/Applications/Alacritty.app/Contents/MacOS/Alacritty" "zsh" "~/" "echo hi"
# ==== Config ====

ALACRITTY_PATH=$1 # for example, "/usr/bin/alacritty"
BASH_OR_ZSH=$2 # for example, "bash"
ROOT_RUN_DIRECTORY=$3 # for example, "~/projects/my_proj/"
RUN_COMMAND=$4 # for example, "./run_script.sh"

# ======= SEARCH FOR, KILL RUN TERMINAL =======
ALACRITTY_WINDOW_TITLE="NvimCodeRunner"

# Even if run through a direct path to alacritty grep will still find it,
# as long as the path contains alacritty (as it should...)
ps_line="$(ps aux | grep alacritty | grep $ALACRITTY_WINDOW_TITLE)"

# Send each line of that (each process) to an element of an array
mapfile -t array_of_processes <<< "$ps_line"

# Loop through and kill
for process in "${array_of_processes[@]}"; do
  process_pid=$(awk '{print $2}' <<< "$process")
  kill $process_pid 2>/dev/null
done


# ===== LAUNCH THE TERMINAL ====
# Now we must append BASH_OR_ZSH to make the window persist
alacritty_passed_command="$BASH_OR_ZSH -c \"cd $ROOT_RUN_DIRECTORY; $RUN_COMMAND; $BASH_OR_ZSH\""

# Build the command
full_alacritty_command="$ALACRITTY_PATH -t $ALACRITTY_WINDOW_TITLE --command $alacritty_passed_command"

# And run
eval "$full_alacritty_command"
