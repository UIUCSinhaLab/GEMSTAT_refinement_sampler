#!/usr/bin/env python
from __future__ import print_function

import scipy as S
import sys

import re

sys.stderr.write("NEVER EVER EVER run this on a server, it executes arbitrary code provided in the template file.\n")

def ret_exec(in_string):
	retval = None
	exec("retval = %s" % in_string)
	return retval

class mydict(dict):
    def __getitem__(self,key):
        if isinstance(key,str) and key.find(":") > -1:
            f_name,the_args = key.split(":")
            retval = None
            exec("retval = %s(%s)" %( f_name, the_args))
            return retval
        else:
            return super(mydict, self).__getitem__(key)


def uniform(low,high):
	return S.random.uniform(low,high)

def log_uniform(low,high):
	return S.exp(uniform(S.log(low),S.log(high)))

def const(val):
	return val

def log(low,high):
	return S.log(uniform(S.exp(low),S.exp(high)))

def normal(mu,std):
	return S.random.normal(mu,std)

#K_range = S.log(S.array([0.01, 10000]))
#a_act_range = S.log(S.array([1, 10]))
#a_rep_range = S.log(S.array([0.00001, 1]))
#coop_range = S.array([1, 100])
#q_btm_range = S.array([0.001, 0.01])

from itertools import count
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--values",default=None,type=str,help="file to get values from for templating")
parser.add_argument("--outpre",default=None,type=str,help="Prefix for generating multiple, files will be OUTPRE_N.par")
parser.add_argument("--N",default=None,type=int,help="Number to generate, ignored if values provided")
parser.add_argument("--base",default=1,type=int,help="Starting point for numbering")
parser.add_argument("--seed",type=int,help="Random seed for reproducible randomness.")
parser.add_argument("INFILE", metavar="IN_FILE", type=str)
#parser.add_argument("OUTFILE", metavar="OUT_FILE", type=str)
args, other = parser.parse_known_args()

if args.seed:
	S.random.seed(args.seed)


foo = mydict()

thetemplate = open(args.INFILE).read()

my_regex = re.compile("{{(.*?)}}")

things = my_regex.findall(thetemplate)
final_template = my_regex.sub("%f",thetemplate)



if args.values:
	#load up the values and whatnot
	values = S.loadtxt(args.values,ndmin=2)
	Num,M = values.shape
	assert M == len(things) , "If you provide values, you must provide all the values."
	for i,one_row in zip(range(args.base,S.minimum(args.N,Num)+args.base),values):
		substituted = final_template % tuple(one_row)
		outfile = open(args.outpre + ("%i.par" % i),"w")
		outfile.write(substituted)
		outfile.close()
	sys.exit(0)

elif args.N == None: #use the templating engine
	replaced_things = [foo[one_thing] for one_thing in things]
	print(final_template.strip() % tuple(replaced_things))
elif args.N >= 1:
	for i in range(args.base,args.base+args.N):
		replaced_things = [foo[one_thing] for one_thing in things]
		substituted = final_template % tuple(replaced_things)
		outfile = open(args.outpre + ("%i.par" % i),"w")
		outfile.write(substituted)
		outfile.close()
