python << EOF
import subprocess
import vdb
import vim

from Queue import Queue, Empty
from threading import Thread


class GDBSession(VDBSession):
    def __init__(self):
        """Sets up a gdb session."""
        self.p = None
        self.daemon = None
        self.queue = None
        self.ready = False
        self.ps1 = '(gdb)'

    def begin(self):
        """Starts a gdb session in the background."""
        self.p = subprocess.Popen(['gdb'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT,
                                stdin=subprocess.PIPE)
        self.queue = Queue()
        self.daemon = Thread(target=self._queue_output)
        self.daemon.daemon = True
        self.daemon.start()
        self.ready = True
        self.execute('set prompt (gdb)\\n')

    def break(self, linenumber):
        """Adds a breakpoint at the specified linenumber."""
        self.execute('break %d' % linenumber)

    def clear(self, linenumber):
        """Clears the breakpoint at the given line."""
        self.execute('clear %d' % linenumber)

    def execute(self, cmd, callback=None):
        """Asynchronously executes a command in gdb, then calls the
        callback function if specified."""
        # First, wait for our turn and block
        while not self.ready:
            time.sleep(0.1)

        # Execute
        self.ready = False
        self.p.stdin.write(command + '\n')

        # TODO THIS IS VERY WRONG MUST HAVE A QUEUE
        # Wait and then run the callback
        if callback is not None:
            while not self.ready:
                time.sleep(0.1)
            callback() 

    def get_line(self):
        """Returns lines from the queue, possibly one at a time."""
        try:
            line = self.queue.get_nowait()
        except Empty:
            self.ready = True
            return None
        else:
            self.ready = False
            return line

    def get_response(self):
        """Returns a string with the latest debugger output, or None if
        nothing is in the queue.
        """
        output = []
        line = get_line()
        while line is not None:
            output.append(line)
            line = get_line()
        return ''.join(output)

    def next(self):
        """Runs the next line."""
        self.execute('next')

    def quit(self):
        """Quits the debugging session cleanly."""
        # execute('quit')
        self.p = None
        self.p.terminate() # or sigkill?
        self.daemon = None
        self.queue = None
        self.ready = False

    def run(self):
        """Runs the debugger."""
        self.execute('run')

    def step(self):
        """Steps into the next function call."""
        self.execute('step')

    def _queue_output(self):
        """Code for a daemon that constantly reads from stdout.

        Reads from stdout, blocking if necessary. If we detect output,
        enqueue the text into our queue.
        """
        for line in iter(self.p.stdout.readline, b''):
            self.queue.put(line)
            if line.strip() == self.ps1:
                self.ready = True
        self.p.stdout.close()


VDB = GDBSession()
EOF
