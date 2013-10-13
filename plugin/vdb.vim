" vdb.vim
" Debug stuff.

function! OpenVDB()
    split
    wincmd j
    wincmd J
    enew
    set buftype=nofile
    py global VDB
    py VDB.start()
endfunction
