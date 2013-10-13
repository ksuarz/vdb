python << EOF
from __future__ import print_function
from Queue import Queue, Empty
from threading import Thread

# TODO the prompt thing is not working properly

import re
import subprocess
import sys
import time
import vim

sys.path.insert(0, '../')
import vdb

class GDBSession(vdb.VDBSession):
    def __init__(self):
        """Sets up a gdb session."""
        self.cmd_queue = None
        self.enqueuer = None
        self.executor = None
        self.msg_queue = None
        self.p = None
        self.ps1 = '(gdb)'
        self.ready = False

    def begin(self):
        """Starts a gdb session in the background."""
        self.p = subprocess.Popen(['gdb'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT,
                                stdin=subprocess.PIPE)

        # This daemon is responsible for capturing output
        self.msg_queue = Queue()
        self.enqueuer = Thread(target=self._queue_output)
        self.enqueuer.daemon = True
        self.enqueuer.start()

        # This daemon executes commands for us, one at a time
        self.cmd_queue = Queue()
        self.executor = Thread(target=self._execute_commands)
        self.executor.daemon = True
        self.executor.start()
        self.ready = True

        # Finally, start gdb and throw away the 
        self.execute('set prompt (gdb)\\n')

    def breakpoint(self, linenumber):
        """Adds a breakpoint at the specified linenumber."""
        self.execute('break %d' % linenumber, lambda: print('Breakpoint added.'))

    def clear(self, linenumber):
        """Clears the breakpoint at the given line."""
        self.execute('clear %d' % linenumber, lambda: print('Breakpoint cleared.'))

    def execute(self, cmd, callback=None):
        """Asynchronously executes a command in gdb, then calls the
        callback function if specified.
        
        This enqueues a task onto the execution pipeline. It safely
        allows multiple commands to be executed asynchronously, then have
        a callback function run once the command finishes.
        """
        task = (cmd, callback)
        self.cmd_queue.put(task)

    def get_line(self):
        """Returns lines from the queue, possibly one at a time."""
        try:
            line = self.msg_queue.get_nowait()
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
        line = self.get_line()
        while line is not None:
            output.append(line)
            line = self.get_line()
        return ''.join(output)

    def next(self):
        """Runs the next line."""
        self.execute('next')

    def quit(self):
        """Quits the debugging session cleanly."""
        self.p.kill()
        self.p = None
        self.enqueuer = None
        self.msg_queue = None
        self.ready = False

    def run(self):
        """Runs the debugger."""
        self.execute('run')

    def step(self):
        """Steps into the next function call."""
        self.execute('step', lambda: print(self.get_output()))

    def _execute_commands(self):
        """Code for a daemon that executes our commands."""
        next = self.cmd_queue.get()
        cmd, callback = next[0], next[1]

        # First, wait for our turn and block
        while not self.ready:
            time.sleep(0.1)

        # Execute
        self.ready = False
        self.p.stdin.write(cmd + '\n')

        # Wait until it's finished, then run the callback
        if callback is not None:
            while not self.ready:
                time.sleep(0.1)
            callback()

    def _queue_output(self):
        """Code for a daemon that constantly reads from stdout.

        Reads from stdout, blocking if necessary. If we detect output,
        enqueue the text into our queue.
        """
        for line in iter(self.p.stdout.readline, b''):
            self.msg_queue.put(line)
            if self.ps1 in line:
                self.ready = True
        self.p.stdout.close()


VDB = GDBSession()
EOF
