
let g:loaded_winsbar = 1

augroup winsbar
    autocmd!
    autocmd VimEnter * :call winsbar#enabled()
augroup END
