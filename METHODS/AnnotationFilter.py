#!/bin/python

# coding: utf-8

# In[2]:


import sys

# In[23]:


import Bio.Alphabet
import Bio.SeqIO as SIO

import numpy as _np


# In[7]:


import gemstat.motifs as GSMOT
import gemstat.seqannotation as GSANNOT
import gemstat.snot as GSSNOT


# In[18]:


from collections import OrderedDict


# In[32]:


def read_motifs(filename):
    return OrderedDict([(i.name, i) for i in GSMOT.read_gemstat_motifs(filename)])


# In[33]:


def filter_dl_annotations(annotations, distance=1):
    dl_annotations = [i for i in annotations if i.motif.name == "dl"]
    other_annotations = [i for i in annotations if i.motif.name != "dl"]
    
    def overlaps(a,b):
        return a.end >= b.start
    
    def interacts(a,b):
        return b.start - a.end <= distance
    
    def too_far(a,b):
        return b.start - a.end > distance+1
    
    accepted = set()
    available = set()
    
    for one_dl in dl_annotations:
        if one_dl.orientation:
            available.add(one_dl)
        else:
            remove_set = set()
            for one_av in available:
                if overlaps(one_av, one_dl):
                    continue
                elif interacts(one_av, one_dl):
                    accepted.add(one_av)
                    accepted.add(one_dl)
                elif too_far(one_av, one_dl):
                    remove_set.add(one_av)
                #probably overlapping
            available.difference_update(remove_set)
    
    final_list = list(accepted)
    final_list.extend(other_annotations)
    final_list.sort(key=lambda x:x.start)
    return final_list
    


# In[31]:


#par_filename = "/Users/lunt/SinhaWorkspace/SinhaSoft/GEMSTAT/examples/03_adding_parameters/start.par"
#seq_filename = "./seqs.fa"
#motif_filename = "./cut_and_dri-mixedcic.wtmx"


# In[7]:


import argparse

parser = argparse.ArgumentParser()
parser.add_argument("par_file",type=str)
parser.add_argument("motif_file",type=str)
parser.add_argument("seq_file",type=str)

args = parser.parse_args()

par_filename = args.par_file
motif_filename = args.motif_file
seq_filename = args.seq_file


# In[34]:


with open(par_filename,"r") as infile:
    params = GSSNOT.load(infile)


# In[92]:


annotation_thresholds = OrderedDict([(i,j["annot_thresh"]) for i,j in params["tfs"].items()])


# In[93]:


the_seqs = SIO.parse(seq_filename,"fasta",alphabet=Bio.Alphabet.IUPAC.unambiguous_dna)


# In[94]:


the_motifs = list(read_motifs(motif_filename).values())


# In[95]:


annotations = [(i, GSANNOT.annotate_sequence(i.seq,the_motifs,et=[annotation_thresholds[j.name] for j in the_motifs])) for i in the_seqs]

annotations = [(i,filter_dl_annotations(j,2)) for i,j in annotations]


# In[99]:


for i, j in annotations:
    print(">{}".format(i.name))
    for k in j:
        print(k)

