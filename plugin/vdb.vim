" vdb.vim
" Debug stuff.

python << EOF
import subprocess
import vim

from Queue import Queue, Empty
from threading import Thread

class DBSession():
    def __init__(self):
        """Initializes a gdb session in the background."""
        self.p = subprocess.Popen(['gdb'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT,
                                stdin=subprocess.PIPE)
        self.queue = Queue()
        self.daemon = Thread(target=self._queue_output)
        self.daemon.daemon = True
        self.daemon.start()
        self.ready = True
        self.p.stdin.write("set prompt (gdb)\\n\n")

    def _queue_output(self):
        """Code for a daemon that constantly reads from stdout.

        Reads from stdout, blocking if necessary. If we detect output, enqueue
        the text into our queue.
        """
        for line in iter(self.p.stdout.readline, b''):
            self.queue.put(line)
        else:
            self.p.stdout.write("\n")
            data = self.p.stdout.readline()
            if data:
                self.queue.put(data)
        self.p.stdout.close()

    def read_output(self):
        """ Reads from stdout of gdb, returning a newline-terminated line or
        None if nothing is in the output queue.
        """
        try:
            line = self.queue.get_nowait()
        except Empty:
            self.ready = True
            return None
        else:
            self.ready = False
            return line

    def add_breakpoint(self, linenumber):
        """Adds a breakpoint at the specified linenumber."""
        self.p.stdin.write("break %d\n" % linenumber)
        # TODO callback
        read()

    def clear_breakpoint(self, linenumber):
        self.p.stdin.write("clear %d\n" % linenumber)
        # TODO callback

    def 


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
GNU gdb (GDB) 7.6.1
Copyright (C) 2013 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-unknown-linux-gnu".
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
