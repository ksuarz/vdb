"""
vdb.py - The public API for the Vim debugger.

Implement these methods and shove your file in the ftplugin folder for your
language-specific debugger.
"""

class VDBSession():
    """The abstract API for Vim debugging sessions."""
    def __init__(self):
        pass

    def break(self, linenumber):
        """Adds a breakpoint at the given line."""
        pass

    def clear(self, linenumber):
        """Clears the breakpoint at the given line."""
        pass

    def execute(self, cmd):
        """Executes the command in the debugger."""
        pass

    def get_response(self):
        """Returns a string with the latest debugger output."""
        pass

    def next(self):
        """Runs the next line."""
        pass

    def quit(self):
        """Quits the debug session cleanly."""
        pass

    def run(self, filename):
        """Runs the debugger."""
        pass

    def start(self):
        """Starts a debugging session."""
        pass

    def step(self):
        """Steps into the next function call."""
        pass

