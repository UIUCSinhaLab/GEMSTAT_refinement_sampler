CHUNK_SIZE = 200

import numpy as np
import glob
import h5py
import gemstat.model as MOD
snot = MOD.snot
import gemstat.matrix as GSM
import os

class GS_Ensemble_Results(object):

    def add_pars_to_group(self, group_object, file_name_template, list_of_ids):
        
        #open an example parfile to figure out how many parameters there are.
        example_param_vector = None
        for one_id in list_of_ids:
            try:
                with open(file_name_template.format(one_id)) as input_snot_file:
                    example_param_vector = snot.load(input_snot_file)
                    break
            except Exception as e:
                continue
                
        if None == example_param_vector:
            raise Exception("Not one of the par files could be loaded.")
            
        N_variables_in_parfile = snot.traverse(example_param_vector).size
        snot.populate(example_param_vector, np.ones(N_variables_in_parfile))
        N_max = np.max([int(i) for i in list_of_ids]) + 1
        
        #also store the par structure somehow.
        group_object.attrs["template"] = snot.dumps(example_param_vector)
        
        
        if not "data" in group_object.keys():
            group_object.create_dataset("data",
                                        shape=(np.max([N_max, CHUNK_SIZE]), N_variables_in_parfile),
                                        chunks=(CHUNK_SIZE, N_variables_in_parfile),
                                        maxshape=(None, N_variables_in_parfile),
                                        compression="lzf",
                                        fillvalue=np.nan,
                                        dtype=self.par_dtype)
        else:
            if N_max > group_object["data"].shape[0]:
                group_object["data"].resize(N_max, axis=0)
        
        
        #actually load the parameters.
        data_group = group_object["data"]
        
        for one_id in list_of_ids:
            try:
                with open(file_name_template.format(one_id)) as input_snot_file:
                    data_group[one_id,:] = snot.traverse(snot.load(input_snot_file))
            except Exception as e:
                pass
        #That's it!
        
        
        

    #TODO: make static @classmethod
    def add_out_to_group(self, group_object, list_of_files, matching_ids):
        data, names = None, None

        #open the first file in the list just to get the shapes we need.
        example_matrix = None
        for one_filename in list_of_files:
            try:
                example_matrix = GSM.GEMSTAT_Matrix.load(one_filename,keep_gt=False)
                break
            except Exception as e:
                print(e)
                continue

        if None == example_matrix:
            raise Exception("Not one of the files could be loaded.")

        N_max = np.max([int(i) for i in matching_ids]) + 1
        NUM_Enhancers, NUM_BINS = example_matrix.storage.shape 

        if not "data" in group_object.keys():
            group_object.create_dataset("data",
                                        shape=(np.max([N_max, CHUNK_SIZE]), example_matrix.shape[0], example_matrix.shape[1]),
                                        chunks=(CHUNK_SIZE, example_matrix.shape[0], example_matrix.shape[1]),
                                        maxshape=(None, example_matrix.shape[0], example_matrix.shape[1]),
                                        compression="lzf",
                                        fillvalue=np.nan,
                                        dtype=self.output_dtype)
        else:
            if N_max > group_object["data"].shape[0]:
                group_object["data"].resize(N_max, axis=0)

        if not "names" in group_object.keys():
            group_object.create_dataset("names",
                                        shape=(example_matrix.shape[0],),
                                        dtype=h5py.special_dtype(vlen=unicode))
            group_object["names"][:] = example_matrix.names
        else:
            pass
            #TODO: Check that the names are the same

        #fill the data
        data = group_object["data"]
        for an_id, a_filename in zip(matching_ids, list_of_files):
            an_id_int = int(an_id)
            try:
                one_mat = GSM.GEMSTAT_Matrix.load(a_filename,keep_gt=False)
                data[an_id_int,:,:] = one_mat.storage[:,:]
            except Exception as e:
                print(e)
                pass

        #DONE, I GUESS?


    def post_process_one_chunk(self, job_method_directory, sub_id_list):
        #1 bring in the final parameters
        #2 bring in the ortho output for all orthologs
        #3 bring in the training output
        
        #print("sub_ids", sub_id_list, "methoddir", job_method_directory)
        
        #1
        #TODO: Implement this
        if not "parameters" in self.f.keys():
            self.f.create_group("parameters")
        params_group = self.f["parameters"]
        self.add_pars_to_group(params_group, os.path.join(job_method_directory,"out","{}.par"), sub_id_list)
        
        #2 Ortho output
        if not "ORTHO" in self.f.keys():
            self.f.create_group("ORTHO")
        h5_ortho_group = self.f["ORTHO"]
        #find the list of orthologs, some runs might have had an error on an ortholog
        ortholog_set = set()
        for one_sub_id in sub_id_list:
            for one_file in glob.iglob(os.path.join(job_method_directory,"crossval","*_{}.out".format(one_sub_id))):
                ortholog_set.add(os.path.basename(one_file).split("_")[0])
        
        #now process all the orthologs we found
        #print("ORTHO SET", ortholog_set)
        for one_ortho in ortholog_set:
            if not one_ortho in h5_ortho_group.keys():
                #print("Keyes", one_ortho, h5_ortho_group.keys())
                h5_ortho_group.create_group(one_ortho)
            h5_one_ortho_group = h5_ortho_group[one_ortho]
            
            files_and_ids = [(os.path.join(job_method_directory,
                                              "crossval",
                                              "{}_{}.out".format(one_ortho, one_id)), one_id) for one_id in sub_id_list]
            files_and_ids = [i for i in files_and_ids if os.path.exists(i[0])]
            load_files, load_ids = zip(*files_and_ids)
            
            #print(load_files, load_ids)
            
            
            self.add_out_to_group(h5_one_ortho_group,load_files, load_ids)
        
        #3 training output
        if not "train" in self.f.keys():
            self.f.create_group("train")
        h5_train_group = self.f["train"]
        files_and_ids = [(os.path.join(job_method_directory,
                                              "out",
                                              "{}.out".format(one_id)), one_id) for one_id in sub_id_list]
        
        files_and_ids = [i for i in files_and_ids if os.path.exists(i[0])]
        load_files, load_ids = zip(*files_and_ids)
        self.add_out_to_group(h5_train_group, load_files, load_ids)
        
    
    def __init__(self, filepath, output_dtype=np.float16, par_dtype=np.float16):
        self.f = None
        self.output_dtype = output_dtype
        self.par_dtype = par_dtype
        self.f = h5py.File(filepath, "a")
        
  
if __name__ == "__main__":
	import argparse
	
	parser = argparse.ArgumentParser(description="fanin for ensemble runs")
	parser.add_argument("dest",type=str, nargs=1,help="Destination H5 file.")
	parser.add_argument("mdir",type=str, nargs=1,help="The method directory to process from")
	parser.add_argument("ints",metavar="N", type=int, nargs="+",help="Which ID to collect")

	args = parser.parse_args()
	print(args)

	a_file = GS_Ensemble_Results(args.dest[0])
	a_file.post_process_one_chunk(args.mdir[0], args.ints)
