" vdb.vim
" Debug stuff.

python << EOF
import subprocess
import vim

from Queue import Queue, Empty
from threading import Thread

class DBSession():
    def __init__(self):
        self.p = subprocess.Popen(['gdb'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT,
                                stdin=subprocess.PIPE)
        self.queue = Queue()
        self.daemon = Thread(target=self._queue_output)
        self.daemon.daemon = True
        self.daemon.start()

    def _queue_output(self):
        """Code for a daemon that constantly reads from stdout.

        Reads from stdout, blocking if necessary. If we detect output,
        enqueue the text into our queue.
        """
        for line in iter(self.p.stdout.readline, b''):
            vim.current.buffer.append(line)
        self.p.stdout.close()

    def read_output(self):
        """Reads from stdout of gdb, returning a newline-terminated
        line or None if nothing is in the output queue.
        """
        try:
            line = self.queue.get_nowait()
        except Empty:
            return None
        else:
            return line


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
