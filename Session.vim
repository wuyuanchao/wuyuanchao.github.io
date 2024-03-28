let SessionLoad = 1
if &cp | set nocp | endif
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/learnspace/technote
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +3 themes/ananke/config.yaml
badd +42 themes/ananke/package.json
badd +1 hugo.toml
badd +12 ~/.vimrc
badd +29 content/posts/my-new-post.md
badd +7 data/menu.toml
badd +7 themes/nostyleplease/layouts/_default/taxonomy.html
badd +1 themes/nostyleplease/layouts/_default/term.html
badd +0 themes/nostyleplease/layouts/partials/back_link.html
badd +21 themes/nostyleplease/layouts/partials/head.html
badd +2 themes/nostyleplease/layouts/_default/single.html
badd +1 themes/nostyleplease/layouts/shortcodes/texi.html
badd +1 themes/nostyleplease/layouts/shortcodes/texd.html
badd +1 themes/nostyleplease/layouts/index.html
badd +1 themes/nostyleplease/config.toml
badd +1 themes/nostyleplease/content/_index.md
badd +2 themes/nostyleplease/data/menu.toml
badd +181 themes/nostyleplease/content/posts/test-highlight.md
argglobal
%argdel
$argadd themes/ananke/config.yaml
edit themes/nostyleplease/data/menu.toml
let s:save_splitbelow = &splitbelow
let s:save_splitright = &splitright
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
let &splitbelow = s:save_splitbelow
let &splitright = s:save_splitright
wincmd t
let s:save_winminheight = &winminheight
let s:save_winminwidth = &winminwidth
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe 'vert 1resize ' . ((&columns * 31 + 59) / 118)
exe 'vert 2resize ' . ((&columns * 86 + 59) / 118)
argglobal
enew
file NERD_tree_tab_1
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal nofen
wincmd w
argglobal
balt themes/nostyleplease/layouts/index.html
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let &fdl = &fdl
let s:l = 49 - ((48 * winheight(0) + 55) / 110)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 49
normal! 02|
wincmd w
2wincmd w
exe 'vert 1resize ' . ((&columns * 31 + 59) / 118)
exe 'vert 2resize ' . ((&columns * 86 + 59) / 118)
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let &winminheight = s:save_winminheight
let &winminwidth = s:save_winminwidth
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
