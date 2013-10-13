" vdb.vim
" Debug stuff.

python << EOF
import vim

# TODO import our vdb.py

VDB = None

def start():
    global VDB
    if VDB is None:
        VDB = DBSession()

def poll():
    global VDB
    if VDB is not None and VDB.p.poll() is None:
        return True
    return False

def read():
    """Reads all text in the output buffer and prints
    it to standard output.
    """
    global VDB
    line = VDB.read_output()
    while line is not None:
        vim.current.buffer.append(line)
        line = VDB.read_output()

def run(command):
    global VDB
    vim.current.buffer.append('(gdb) ' + command)
    VDB.p.stdin.write(command + '\n')
EOF

function! OpenVDB()
    split
    wincmd j
    wincmd J
    enew
    set buftype=nofile
    py start()
endfunction
