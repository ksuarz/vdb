" vdb.vim
" Debug stuff.

sign define breakpoint text=!! texthl=Search
sign define currentline text==> texthl=Search

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
    python global VDB
    exec ":py VDB.breakpoint(int(" . linenumber . "))"
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
    exec ":py VDB.execute(\"" . a:cmd . "\")"
    wincmd j
    wincmd p
endfunction

function! VDBNext(type)
    py global VDB
    if a:type ==# "next"
        py VDB.next()
    elseif a:type ==# "step"
        py VDB.step()
    py VDB.get_response()

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
    wincmd J
    q
    sign unplace *
endfunction

function! VDBRun()
python << EOF
global VDB
VDB.run()
EOF
    py global VDB
    py VDB.run()
    py VDB.get_response()
endfunction
