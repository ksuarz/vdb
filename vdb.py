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
