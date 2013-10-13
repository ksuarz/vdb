" vdb.vim
" Debug stuff.

python << >>
class DBSession():
    def __init__():
        self.p = subprocess.Popen(['gdb'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT,
                                stdin=subprocess.PIPE)

VDB = None

def start():
    VDB = DBSession()

def poll():
    if VDB.p.poll() is None:
        print 'gdb is running!'
    else:
        print 'gdb is not running!'
>>
