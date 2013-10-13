" vdb.vim
" Debug stuff.

function! OpenVDB()
    split
    wincmd j
    wincmd J
    enew
    set buftype=nofile
    py start()
endfunction
