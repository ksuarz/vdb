" vdb.vim
" Debug stuff.

python << EOF
import subprocess


class DBSession():
    def __init__(self):
        self.p = subprocess.Popen(['gdb'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT,
                                stdin=subprocess.PIPE)

VDB = None

def start():
    global VDB
    VDB = DBSession()

def poll():
    global VDB
    if VDB is not None and VDB.p.poll() is None:
        print 'gdb is running!'
    else:
        print 'gdb is not running!'

def read():
    global VDB
    for x in xrange(0, 9):
        print VDB.p.stdout.readline(),

def run(command):
    global VDB
    VDB.p.stdin.write(command + '\n')
    print '(gdb) ' + command
    print VDB.p.stdout.readline(),
EOF
