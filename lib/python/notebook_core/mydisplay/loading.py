from __future__ import print_function

import glob
import os.path
import scipy as S

from gemstat.matrix import *

def load_outfile(fname):
    return S.loadtxt(fname, converters={0:lambda x:0})[1:,1:]

#Load the predictions from all samples
def load_samples(one_jobid,JOBBASE,subdir="samples/out",munge="*.out"):
    one_jobid = str(one_jobid)
    JOBBASE=str(JOBBASE)
    subdir=str(subdir)
    munge=str(munge)
    
    all_outfiles = glob.glob(os.path.join(JOBBASE, one_jobid, subdir, munge))
    all_outfiles.sort()
    #print all_outfiles
    
    all_full_out_matrices = [GEMSTAT_Matrix.load(i) for i in all_outfiles]
    out_matrix_true = all_full_out_matrices[0].separate_output()[0]
    all_out_matrices = [i.separate_output()[1] for i in all_full_out_matrices]
    
    #read_predictions = S.vstack(all_out_matrices)
    #read_predictions[read_predictions > 1.0] = 1.0
    
    #print("READ ", len(read_predictions))
    return all_out_matrices, out_matrix_true
