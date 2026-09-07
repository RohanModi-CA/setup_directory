
alias piomonitor='pio run -e uno -t monitor'
alias piorunupload='pio run -e uno -t upload -t monitor'

#!/bin/bash

alias iphone="/home/thinkpad/Documents/FileFolder/setup/scripts/iphone/iphone.sh"

alias topdf="/home/thinkpad/Documents/FileFolder/setup/scripts/to-pdf/to-pdf.sh"

# do this in genvenv	
alias rmmouse="env -u SSH_AUTH_SOCK remouse --password 'oaqy1Obm47'"
alias reactivate='source /home/thinkpad/Documents/FileFolder/Projects/BlocksSSH/activate'
alias dontsleep='nosuspend'
alias nosuspend='systemd-inhibit --what=handle-lid-switch sleep infinity'

dualmpv() {
    local file="$1"
    local sid1="$2"
    local sid2="$3"

    mpv --sid="$sid1" --secondary-sid="$sid2" "$file"
}


alias rmxopp='/home/thinkpad/Documents/FileFolder/Projects/rm-xopp-converter/.venv/bin/python3 /home/thinkpad/Documents/FileFolder/Projects/rm-xopp-converter/main.py'


pyfixqt () {
python3 - <<'PY' "$@"
import os, runpy, sys, cv2
os.environ.pop("QT_QPA_PLATFORM_PLUGIN_PATH", None)
os.environ.pop("QT_QPA_FONTDIR", None)
os.environ.pop("QT_PLUGIN_PATH", None)
script = sys.argv[1]
sys.argv = sys.argv[1:]
runpy.run_path(script, run_name="__main__")
PY
}


alias cdblocks="cd /home/thinkpad/Documents/FileFolder/Projects/BlocksSSH"

alias signinremarkable="sshpass -p 'oaqy1Obm47' ssh root@10.11.99.1"

alias remarkablepassword="echo oaqy1Obm47 | clip"
alias pinta='flatpak run com.github.PintaProject.Pinta'
alias matlabinstall='/home/thinkpad/TarApps/matlab/mpm
 install --release=R2025b --destination=/home/thinkpad/TarApps/matlab/ --products'
alias mlab='matlab -nodesktop'
alias matlabrun='matlab -batch'
alias matlab='/usr/local/MATLAB/R2025b/bin/matlab'
alias xelatex='xelatex -interaction=nonstopmode -halt-on-error'
alias clean_p_files='python3 /home/thinkpad/Documents/FileFolder/Projects/rmtools/rmtools/pipelines/clean_p_files.py'
alias editable_rmtools_pip='pip install -e /home/thinkpad/Documents/FileFolder/Projects/rmtools'
alias rmtools_pip_non_e='pip install /home/thinkpad/Documents/FileFolder/Projects/rmtools'
alias quinzestuff='/home/thinkpad/Documents/FileFolder/setup/scripts/dirstuff/quinzestuff.sh -R /home/thinkpad/Documents/FileFolder/Obsidian/QuinzePlus | clip' 

alias quinzestuffs='/home/thinkpad/Documents/FileFolder/setup/scripts/dirstuff/quinzestuff.sh -R -s /home/thinkpad/Documents/FileFolder/Obsidian/QuinzePlus | clip' 

alias cdobsidian='cd /home/thinkpad/Documents/FileFolder/Obsidian'
alias dirstuff='python3 ~/Documents/FileFolder/setup/scripts/dirstuff/dirstuff.py'
alias rm='trash'
alias P38gen="source ~/.venvs/P38gen/bin/activate"
alias genvenv="source ~/.venvs/general/bin/activate"
alias qtvenv="source ~/.venvs/general_sysqt/bin/activate"
alias aistudio='echo "Always use \$ and \$\$ formatting for math. Make sure all math expressions, including their delimeters, are on the same line. Ensure there are no spaces between the starts and ends of math and their delimeters" | clip'
alias downloadnotes='/home/thinkpad/Documents/FileFolder/Projects/note-imap-thing/.venv/bin/python3 /home/thinkpad/Documents/FileFolder/Projects/note-imap-thing/main.py'
alias termhere='alacritty --working-directory $(pwd) &'
alias activatevenv='source .venv/bin/activate'
alias gdb='gdb -q'
alias createvenv='python3 -m venv .venv/'
alias disconnectheadphones='bluetoothctl disconnect B0:38:E2:5D:FE:C0'
alias ai='/home/thinkpad/Documents/FileFolder/Projects/aistudio_cli/.venv/bin/python3 /home/thinkpad/Documents/FileFolder/Projects/aistudio_cli/main.py'
alias recentclip='recentfile=$(ls -t | head -n 1 2>/dev/null); if [ -n "$recentfile" ]; then realpath "$recentfile" | clip; fi; echo "$recentfile"'
alias ctmux="/home/thinkpad/Documents/FileFolder/setup/cvim_tmux_startup.sh"
alias doublesider="/home/thinkpad/Documents/FileFolder/Projects/doublesider/.venv/bin/python3 /home/thinkpad/Documents/FileFolder/Projects/doublesider/DoubleSider.py"
alias pipvenv='.venv/bin/pip3'
alias py3venv='.venv/bin/python3'
alias pyvenv='.venv/bin/python3'
alias venvpy='.venv/bin/python3'
alias nmpv='mpv -scale=nearest'
alias lazy='NVIM_APPNAME=nvim-lazyvim nvim'
alias cvim='NVIM_APPNAME=nvim-c nvim'
alias vim='nvim'
alias clip='xclip -selection clipboard'
# alias clip='wl-copy'
alias cdkavimtex='cd ~/.local/share/nvim/plugged/KaVimTeX'
alias gsave='git commit -am "fixes" && git push origin rohanmodi && vim -c "PlugUpdate" -c "exit" -c "exit"'
alias mdkir='mkdir'
alias cls='clear'
alias cdprojects='cd ~/Documents/FileFolder/Projects'
alias cdschool='cd ~/Documents/FileFolder/School'
alias cdfiles='cd ~/Documents/FileFolder/'
alias cdphysics='cdschool'
alias cdthermal253='cdphysics && cd thermal253'
alias cdquantum357='cdphysics && cd quantum357'
alias cdvectorcalc248='cdphysics && cd vectorcalc248'
alias cdexpmeth257='cdphysics && cd expmeth257'
alias cdmodern260='cdphysics && cd modern260'
alias 'cd..'='cd ..'
alias 'cd....'='cd .. && cd ..'
alias 'cd......'='cd.... && cd..'
alias cdlua='cd ~/.config/nvim/lua/llvp'
alias vimsetup='vim ~/Documents/FileFolder/setup/VimSetup.vim'
alias cvimsetup='vim ~/Documents/FileFolder/setup/CVimSetup.vim'
alias cdsetup='cd ~/Documents/FileFolder/setup/'
alias bashsetup='vim ~/Documents/FileFolder/setup/BashSetup.sh'
alias dunstsetup='vim ~/.config/dunst/dunstrc'
alias sxhkdsetup='vim ~/.config/sxhkd/sxhkdrc'
alias cdtelechargements='cd ~/Téléchargements/'
alias 'cdrohanmodi.ca'='cdprojects && cd rohanmodi.ca/'
alias cdminefield='cdprojects && cd.. && cd minefield'
alias vimtodo='vim /home/thinkpad/Documents/FileFolder/12.0/todo.twelve-o'
alias todo='vim /home/thinkpad/Documents/FileFolder/12.0/todo.twelve-o'
alias todovim='vim /home/thinkpad/Documents/FileFolder/12.0/todo.twelve-o'
alias ':q'='echo You are not editing a file, dummy.'
alias ':wq'=':q'
alias 'q'=':q'
alias 'wq'=':q'
alias ':q!'=':q'
alias 'please'='sudo !!'
alias 'btclip'='sudo btclip; exit'
alias "i3reload"='i3-msg reload'
alias 'i3setup'='vim ~/.config/i3/config'
alias 'swaysetup'='vim ~/.config/sway/config'
alias 'vttest'='vimtex ~/Documents/FileFolder/School/PHYS103/PS4/Q3.tex'
alias 'vimt'='nvim -c "KVTServer" -c "VimtexCompile" -c "VimtexClean" -c "redraw!"'
alias 'wait'='sleep'
export PATH="$PATH:/opt/nvim/"
export PATH="$PATH:/opt/cleantex/"
export PATH="$PATH:/opt/btclip/"
alias 'photo'='eog'
alias 'reloadbashrc'='source ~/.bashrc'
alias pastephoto='xclip -selection clipboard -t image/png -o > '





# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"


# alias vimtex='(/home/rohan/.local/share/nvim/plugged/KaVimTex/lua/start.sh > /dev/null &); vim -c "KVTServer" -c "VimtexCompile"'


#      _  __  __      ___        _______  __   __
#     | |/ /  \ \    / (_)      |__   __| \ \ / /
#     | ' / __ \ \  / / _ _ __ ___ | | ___ \ V / 
#     |  < / _` \ \/ / | | '_ ` _ \| |/ _ \ > <  
#     | . \ (_| |\  /  | | | | | | | |  __// . \ 
#     |_|\_\__,_| \/   |_|_| |_| |_|_|\___/_/ \_\
                                            

KVTlayout_path="/home/thinkpad/Documents/FileFolder/minefield/minefield.json"

# Get the window ID using the PID
KVTkitty_window_id=$(xdotool search --pid $PPID)

# Unmap and remap commands
KVTunmap="xdotool windowunmap '$KVTkitty_window_id'"
KVTremap="xdotool windowmap '$KVTkitty_window_id'"

# Execute Neovim commands
KVTnvimcommand='nvim -c "KVTServer" -c "VimtexCompile" -c "redraw!"'

alias vimtex="i3-msg append_layout $KVTlayout_path > /dev/null && $KVTunmap && $KVTremap && $KVTnvimcommand"


alias headphonesconnectbluetooth='bluetoothctl connect B0:38:E2:5D:FE:C0'

export LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

export BROWSER='/usr/bin/firefox'           # default web browser

      
export PATH="$PATH:/home/thinkpad/.cargo/bin"



# --- Copy this to the bottom of ~/.bashrc ---

# 1. Function to find the current git branch
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# 2. Define colors (optional, but makes it readable)
RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"
YELLOW="\[\033[0;33m\]"
BLUE="\[\033[0;34m\]"
NO_COLOR="\[\033[0m\]"

# 3. Set the Prompt Structure (PS1)
# Structure: [User@Host] [Directory] [Git Branch] $
export PS1="${GREEN}\u@\h${NO_COLOR}:${BLUE}\w${YELLOW}\$(parse_git_branch)${NO_COLOR}\$ "

unset VIMRUNTIME
