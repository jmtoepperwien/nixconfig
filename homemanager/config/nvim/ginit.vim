" Enable Mouse
set mouse=

if exists("g:neovide")
    set guifont=SauceCodePro\ Nerd\ Font\ Mono:h18
    let g:neovide_cursor_animation_length = 0.0
    let g:neovide_cursor_trail_size = 0
    let g:neovide_scroll_animation_far_lines = 0
    let g:neovide_scroll_animation_length = 0
    let g:neovide_hide_mouse_when_typing = v:true
endif

if exists(':GuiFont')
    " Use GuiFont! to ignore font errors
    GuiFont SauceCodePro\ Nerd\ Font\ Mono:h18
endif

if exists(':GuiTabline')
    GuiTabline 0
endif

if exists(':GuiPopupmenu')
    GuiPopupmenu 0
endif

if exists(':GuiScrollBar')
    GuiScrollBar 0
endif

if exists(':GuiRenderLigatures')
  GuiRenderLigatures 0
endif

" Right Click Context Menu (Copy-Cut-Paste)
nnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>
inoremap <silent><RightMouse> <Esc>:call GuiShowContextMenu()<CR>
xnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>gv
snoremap <silent><RightMouse> <C-G>:call GuiShowContextMenu()<CR>gv
