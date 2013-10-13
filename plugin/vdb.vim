" vdb.vim
" Debug stuff.

python << EOF
import subprocess

from Queue import Queue, Empty
from threading import Thread

class DBSession():
    def __init__(self, ps1):
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

    def _queue_output(self):
        """Code for a daemon that constantly reads from stdout.

        Reads from stdout, blocking if necessary. If we detect output, enqueue
        the text into our queue.
        """
        for char in iter(self.p.stdout.read, b''):
            self.queue.put(char)
        self.p.stdout.close()

    def read_output(self):
        """ Reads from stdout of gdb, returning a newline-terminated line or
        None if nothing is in the output queue.
        """
        try:
            line = self.queue.get_nowait()
        except Empty:
            return None
        else:
            return line

    def add_breakpoint(self, linenumber):
        """Adds a breakpoint at the specified linenumber."""
        self.p.stdin.write("break %d" % linenumber)
        # TODO callback
        read()



VDB = None

def start():
    """Starts a new debugging session."""
    VDB = DBSession("(gdb)")

def read():
    """
    Reads all text in the output buffer and prints it to standard output.
    """
    line = VDB.read_output()
    while line is not None:
        print line
        line = VDB.read_output()

def run(command):
    global VDB
    VDB.p.stdin.write(command + '\n')
    print '(gdb) ' + command
        # don't worry about this yet dawg
    print VDB.p.stdout.readline(),
EOF
