"""
vdb.py - The public API for the Vim debugger.

Implement these methods and shove your file
in the ftplugin folder for your language-specific debugger.

This base class is used for testing, so if you don't implement
a certain method, it will still work
"""
import vim


class VDBSession():
    """The abstract API for Vim debugging sessions."""
    def __init__(self):
        self.prompt = "(vdb)"

    def begin(self):
        """Starts a debugging session."""
        self.execute("start")
        self.output("vdb started!")

    def breakpoint(self, linenumber):
        """Adds a breakpoint at the given line."""
        self.execute("break " + str(linenumber))
        output_string = "Breakpoint set at {0}".format(linenumber)
        self.output(output_string)

    def clear(self, linenumber):
        """Clears the breakpoint at the given line."""
        self.execute("clear " + str(linenumber))
        output_string = "Breakpoint cleared at {0}".format(linenumber)
        self.output(output_string)

    def execute(self, cmd):
        """Executes the command in the debugger."""
        output_string = "{0} {1}".format(self.prompt, cmd)
        self.output(output_string)

    def get_response(self):
        """Returns a string with the latest debugger output."""
        pass

    def next(self):
        """Runs the next line."""
        self.execute("next")

    def quit(self):
        """Quits the debug session cleanly."""
        self.execute("quit")
        self.output("Shutting down...")

    def run(self, filename):
        """Runs the debugger."""
        self.execute("run")
        self.output("Running the application")

    def step(self):
        """Steps into the next function call."""
        self.run("step")

    def output(self, output_string):
        vim.current.buffer.append(output_string)
