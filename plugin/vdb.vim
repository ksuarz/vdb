" vdb.vim
" Debug stuff.

python << EOF

import os
import subprocess
import system
import vim

p = subprocess.Popen(['gdb', '/home/ksuarz/Programming/sorted-list/sl'],
                     stdin=subprocess.PIPE,
                     stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE)

out, err = p.communicate(None)
print out
print err
p.terminate()

EOF

function! VDB(command)
endfunction
