"set number
"filetype plugin on
" syntax enable
"set tabstop=4
"set shiftwidth=4
set wildignore+=*.pdf
luafile /home/gram/Documents/FileFolder/setup/VimSetup.lua
"set foldmethod=indent
command W write
command Q quit

command SNIPPETHELP execute "! cat /home/gram/Documents/FileFolder/setup/snipsref.txt"

" command VTNBCompile 'so /home/gram/Documents/FileFolder/Projects/vtnb/lua/vtnb_compile/init.lua'
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



" " Start Vim-Plug
" call plug#begin()
" 
" Plug 'lervag/vimtex'
" Plug 'sirver/ultisnips'
" Plug 'RohanModi-CA/KaVimTeX', { 'branch': 'rohanmodi' }
" 
" Plug 'RohanModi-CA/vt-shortcuts', { 'branch': 'rohanmodi' }
" Plug 'RohanModi-CA/vtnb', { 'branch': 'rohanmodi' }
" 
" call plug#end()
" " End Vim-Plug
" 

" Open alacrity in this directory 
command! Alacritty execute '!alacritty --working-directory ' . shellescape(getcwd()) . ' &'
command! Termhere execute '!alacritty --working-directory ' . shellescape(getcwd()) . ' &'
