" c.vim - Python code for interacting with gdb.
" Known issues/bugs:
" - Don't try setting a breakpoint at a nonexistent line.
" - Don't put multiple breakpoints on one line

python << EOF
from __future__ import print_function
from Queue import Queue, Empty
from threading import Thread

import re
import subprocess
import sys
import os
import time
import vim

sys.path.insert(0, os.path.expanduser('~/.vim/bundle/vdb'))
import vdb

class GDBSession(vdb.VDBSession):
    def __init__(self):
        """Sets up a gdb session."""
        # Queues, daemons, and other global variables
        self.cmd_queue = None
        self.enqueuer = None
        self.executor = None
        self.msg_queue = None
        self.p = None
        self.ps1 = '(gdb)'
        self.ready = False

        # Regular expressions - don't try this at home
        self.where = re.compile(r'.* at (?P<file>.+):(?P<line>\d+)$', re.M)
        self.bkpnt = re.compile(r'^Breakpoint (P<id>\d+)\s.*$', re.M)
        self.clear = re.compile(r'Deleted breakpoint.*(P<id>\d+).*$', re.M)

    def begin(self):
        """Starts a gdb session in the background."""
        self.p = subprocess.Popen(['gdb', '/home/ksuarz/Programming/tokenizer/tokenizer'],
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
        # TODO use execute2
        # self.execute('set prompt (gdb)\\n', lambda: vim.command('echo("gdb started!")'))
        # TODO check vim buffer.append that doesn't like newlines
        self.execute('set prompt (gdb)\\n')

    def breakpoint(self, linenumber):
        """Adds a breakpoint at the specified linenumber."""
        self.execute('break %d' % linenumber, self._callback_set_breaksign)

    def clear(self, linenumber):
        """Clears the breakpoint at the given line."""
        self.execute('clear %d' % linenumber, lambda: vim.command('echo("Breakpoint cleared.")'))

    def execute(self, cmd, callback=None, args=None):
        """Asynchronously executes a command in gdb, then calls the
        callback function if specified.
        
        This enqueues a task onto the execution pipeline. It safely
        allows multiple commands to be executed asynchronously, then have
        a callback function run once the command finishes.
        """
        response = self.execute2(cmd)
        for string in response.split('\n'):
            vim.current.buffer.append(string)

    def execute2(self, cmd):
        """Blocks until the last command returns."""
        while not self.ready:
            time.sleep(0.1)

        self.ready = False
        self.p.stdin.write(cmd + '\n')

        while not self.ready:
            time.sleep(0.1)
        
        return self.get_response_as_string()


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
        """Writes the latest debugger output to the current buffer; if
        nothing is in the queue, nothing happens."""
        output = []
        line = self.get_line()
        while line is not None:
            output.append(line)
            line = self.get_line()
            # TODO vim doesn't like newlines
        vim.current.buffer.append(''.join(output))

    def get_response_as_string(self):
        """Returns the latest debugger output as a string, or None if
        nothing is in the queue."""
        output = []
        line = self.get_line()
        while line is not None:
            output.append(line)
            line = self.get_line()
        return ''.join(output)

    def set_globals(self):
        """Sets important global variables in Vim."""
        self.execute('where', self._callback_set_linenumber, linenumber)

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

    def _callback_set_currents(self):
        """Callback that sets the current filename and line number."""
        line = self.get_response_as_string()
        match = self.where.search(line)
        if match:
            vim.command('let g:vdb_current_line = ' + match.group('line'))
            vim.command('let g:vdb_current_file = ' + match.group('file'))
        else:
            vim.command('let g:vdb_current_line = 0')
            vim.command('let g:vdb_current_line = "/"')

    def _callback_set_breaksign(self):
        """Callback that sets a sign at the given linenumber."""
        linenumber = 100
        line = self.get_response_as_string()
        match = self.bkpnt.search(line)
        if match:
            vim.command('exec ":sign place {1} line={2} name=breakpoint file=" . @%'.format(match.group('id'), linenumber))
        else:
            vim.command('echo "Adding the breakpoint failed."')

    def _callback_see_output(self):
        vim.command('wincmd j')


    def _execute_commands(self):
        """Code for a daemon that executes our commands."""
        while True:
            next = self.cmd_queue.get()
            cmd, callback, args = next[0], next[1], next[2]

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
                if args is None:
                    callback()
                else:
                    callback(args)

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

    def _scratch_output(self):
        """Dumps the content of the output buffer into the scratch space."""


VDB = GDBSession()
EOF







