#!/bin/env python
CHUNK_SIZE = 200

import numpy as np
import glob
import h5py
import gemstat.model as MOD
snot = MOD.snot
import gemstat.matrix as GSM
import os



if __name__ == "__main__":
	import argparse

	parser = argparse.ArgumentParser(description="Get par from HDF5 file.")
	parser.add_argument("hfile",type=str, nargs=1,help="Source H5 file.")
	parser.add_argument("pnumber",type=int, nargs=1,help="Which par to get, 0 indexed.")

	path_to_pars = "parameters"

	args = parser.parse_args()

	f = h5py.File(args.hfile[0],"r")
	pars_data = f[path_to_pars]

	snot_template = pars_data.attrs["template"]
	snot_object = snot.loads(snot_template)

	one_par_vector = pars_data[args.pnumber[0],:]
	snot.populate(snot_object,one_par_vector)

	print(snot.dumps(snot_object))
	f.close()
