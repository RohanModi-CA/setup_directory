set termguicolors
let g:SETUP_DIRECTORY = '/home/thinkpad/Documents/FileFolder/setup/'
let g:python3_host_prog = '/home/thinkpad/.local/bin/pynvim-python'


set number
filetype plugin on
syntax enable
syntax sync fromstart
set tabstop=4
set shiftwidth=4
set wildignore+=*.pdf
command W write
command Q quit

execute 'source ' . g:SETUP_DIRECTORY . 'coc_defaults.vim'

command SNIPPETHELP execute "! cat /home/thinkpad/Documents/FileFolder/setup/snipsref.txt"
" command VTNBCompile 'so /home/thinkpad/Documents/FileFolder/Projects/vtnb/lua/vtnb_compile/init.lua'
map i a



" Start VimTeX
let g:vimtex_view_method = 'zathura'
let g:maplocalleader = '\'
let g:tex_flavor='latex'


let g:vimtex_compiler_latexmk = {
	    \ 'options' : [
    \    '-shell-escape',
    \    '-verbose',
    \    '-file-line-error',
    \    '-synctex=1',
	\	 '-8bit',
    \    '-interaction=nonstopmode',
    \ ],
            \ 'out_dir' : '.resources/pdf',
            \}
let g:vimtex_view_forward_search_on_start = 0
let g:KVTpdf_dir = ".resources/pdf"




"set conceallevel=1
"let g:tex_conceal='abdmg'
" End VimTeX

" Start UltiSnips
let g:UltiSnipsExpandTrigger = '<Tab>'
let g:UltiSnipsJumpForwardTrigger = '<Tab>'
let g:UltiSnipsJumpBackwardTrigger = '<S-Tab>'
let g:UltiSnipsSnippetDirectories=[$HOME."/Documents/FileFolder/setup/UltiSnips"]
" End UltiSnips

"Plug 'RohanModi-CA/KaVimTeX', { 'commit': '1457c1e2240b7b644f31cec846ee7ab5b65cfbbb'}



"Start Vim-Plug
call plug#begin()
 
 Plug 'lervag/vimtex'
 Plug 'sirver/ultisnips'
 Plug 'RohanModi-CA/KaVimTeX', { 'branch': 'rohanmodi' }
 
 Plug 'RohanModi-CA/vt-shortcuts', { 'branch': 'rohanmodi' }
 Plug 'RohanModi-CA/vtnb', { 'branch': 'rohanmodi' }

 Plug 'folke/tokyonight.nvim'
Plug 'nvim-tree/nvim-tree.lua', { 'tag': 'v1.3.0' }

 Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'navarasu/onedark.nvim'

Plug 'nvim-lualine/lualine.nvim'
" If you want to have icons in your statusline choose one of these
Plug 'nvim-tree/nvim-web-devicons'

 call plug#end()
" End Vim-Plug
"


" Open alacrity in this directory 
command! Alacritty execute '!alacritty --working-directory ' . shellescape(getcwd()) . ' &'
command! Termhere execute '!alacritty --working-directory ' . shellescape(getcwd()) . ' &'

command! Nautilus execute '!nautilus ' . shellescape(getcwd()) . ' &'

command! Syntax execute 'syntax sync fromstart'


" ===== RUNSCRIPT =====

function! Execute_runscript()
  " Runscript Module
  let s:alacritty_run_terminal_path = "/home/thinkpad/Documents/FileFolder/setup/alacritty_run_terminal.sh"
  let s:current_dir = getcwd()
  let s:alacritty_path = "/usr/bin/alacritty"
  let s:bash_or_zsh = "bash"
  let s:runscript = "runscript.sh"

  let s:command = printf('%s "%s" "%s" "%s" "%s" "%s"', s:alacritty_run_terminal_path, s:alacritty_path, s:bash_or_zsh, s:current_dir, s:runscript, "2")

  call system(s:command)

endfunction

command! Run call Execute_runscript()


"colorscheme tokyonight
colorscheme tokyonight-day


nnoremap <LocalLeader>t :NvimTreeToggle<CR>
nnoremap <LocalLeader>r :CocRestart<CR>

execute 'luafile ' . g:SETUP_DIRECTORY . 'VimSetup.lua'




