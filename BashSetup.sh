alias termhere='alacritty --working-directory $(pwd) &'
alias gdb='gdb -q'
alias createvenv='python3 -m venv .venv/'
alias disconnectheadphones='bluetoothctl disconnect B0:38:E2:5D:FE:C0'
alias ai='/home/gram/Documents/FileFolder/Projects/aistudio_cli/.venv/bin/python3 /home/gram/Documents/FileFolder/Projects/aistudio_cli/main.py'
alias recentclip='recentfile=$(ls -t | head -n 1 2>/dev/null); if [ -n "$recentfile" ]; then realpath "$recentfile" | clip; fi; echo "$recentfile"'
alias ctmux="/home/gram/Documents/FileFolder/setup/cvim_tmux_startup.sh"
alias doublesider="/home/gram/Documents/FileFolder/Projects/doublesider/.venv/bin/python3 /home/gram/Documents/FileFolder/Projects/doublesider/DoubleSider.py"
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
alias vimtodo='vim /home/gram/Documents/FileFolder/12.0/todo.twelve-o'
alias todo='vim /home/gram/Documents/FileFolder/12.0/todo.twelve-o'
alias todovim='vim /home/gram/Documents/FileFolder/12.0/todo.twelve-o'
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
                                            

KVTlayout_path="/home/gram/Documents/FileFolder/minefield/minefield.json"

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
