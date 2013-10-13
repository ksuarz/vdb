" vd.vim
" Debug stuff.

sign define breakpoint text=!! texthl=Search
sign define currentline text==> texthl=Search

let g:vdb_break_id = 2
let g:vdb_current_file = "/"
let g:vdb_current_line = 0
let g:vdb_loaded_scratch = 0
let g:vdb_next_file = "/"
let g:vdb_next_line = 0

" Begins a new VDB, spawning an instance of the debugger in the background.
function! VDBStart()
    split
    wincmd j
    wincmd J
    enew
    set buftype=nofile
    py global VDB
    py VDB.begin()
    wincmd p
endfunction

" Adds a breakpoint at the current line.
function! VDBBreak()
    let linenumber = line(".")
    wincmd j
    python global VDB
    exec ":py VDB.breakpoint(int(" . linenumber . "))"
    wincmd p
    exec ":sign place " . g:vdb_break_id . " line=" . linenumber . " name=breakpoint file=" . @%
    let g:vdb_break_id = g:vdb_break_id + 1 
endfunction

" Clears the breakpoint at the current file.
function! VDBClear()
    let linenumber = line(".")
    py global VDB
    exec ":py VDB.clear(int(" . linenumber . "))"
    sign unplace
endfunction

function! VDBExecute(cmd)
    " TODO callback and normal G
    py global VDB
    wincmd j
    exec ":py VDB.execute(\"" . a:cmd . "\")"
    wincmd p
endfunction

function! VDBNext(type)
    py global VDB
    if a:type ==# "next"
        py VDB.next()
    elseif a:type ==# "step"
        py VDB.step()
    endif
    if g:vdb_current_line !=# 0
        exec ":sign jump 1 file=" . g:vdb_current_file
        sign unplace
    endif
    exec ":sign place 1 line=" . g:vdb_next_line . " name=currentline file=" . g:vdb_next_file
    exec ":sign jump 1 file=" . g:vdb_next_file
    let g:vdb_current_file = g:vdb_next_file
    let g:vdb_current_line = g:vdb_next_line
endfunction

function! VDBQuit()
    wincmd j
    q
    sign unplace *
endfunction

function! VDBRun()
    py global VDB
    py VDB.run()
endfunction
