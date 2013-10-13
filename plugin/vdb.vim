" vdb.vim
" Debug stuff.

sign define breakpoint text=!! texthl=Search
sign define currentline text==> texthl=Search
let g:vdb_break_id = 1
let g:vdb_next_line = 0
let g:vdb_next_file = "/"
let g:vdb_current_line = 0
let g:vdb_current_file = "/"

function! VDBStart()
    split
    wincmd j
    wincmd J
    enew
    set buftype=nofile
    "py global VDB
    "py VDB.start()
    wincmd p
endfunction

function! VDBBreak()
    let linenumber = line(".")
    "py global VDB
    "exec ":py VDB.break(int(" . linenumber . "))"
    exec ":sign place " . g:vdb_break_id . " line=" . linenumber . " name=breakpoint file=" . @%
    let g:vdb_break_id = g:break_id + 1
endfunction

function! VDBClear()
    let linenumber = line(".")
    "py global VDB
    "exec ":py VDB.clear(int(" . linenumber . "))"
    sign unplace
endfunction

function! VDBExecute(cmd)
    "py global VDB
    "exec ":py VDB.execute(" . a:cmd . ")"
    wincmd J
    "py VDB.get_response()
    wincmd p
endfunction

function! VDBNext()
    py global VDB
    py VDB.next()
    py VDB.get_response()
    exec ":sign place " . g:vdb_next
endfunction
