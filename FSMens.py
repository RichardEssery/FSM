#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Run an ensemble of FSM simulations

Richard Essery
School of GeoSciences
University of Edinburgh
"""

import numpy as np
import os
import sys

namelist = sys.argv[1]
os.system('./compil.sh')

try:
    os.mkdir('output')
except:
    pass

for n in range(32):
    config = np.binary_repr(n, width=5)
    print 'Running FSM configuration ',config,n
    f = open('nlst.txt', 'w')
    out_file = 'out.txt'
    with open(namelist) as file:
        for line in file:
            f.write(line)
            if 'config' in line:
                f.write('  nconfig = '+str(n)+'\n')
            if 'out_file' in line:
                out_file = line.rsplit()[-1]
            out_name = out_file.replace('.txt','')
    f.close()
    os.system('./FSM < nlst.txt')
    save_file = 'output/'+out_name+'_'+config+'.txt'
    os.system('mv '+out_file+' '+save_file)
os.system('rm nlst.txt')

