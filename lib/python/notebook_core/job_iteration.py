
import os
import os.path
import glob as _glob
import re as _re

from gemstat.matrix import GEMSTAT_Matrix

def _load_samples(basedir_ls,munge="*.out"):
    all_outfiles = _glob.glob(os.path.join(basedir_ls, munge))
    all_outfiles.sort()
    #print all_outfiles
    
    all_full_out_matrices = [GEMSTAT_Matrix.load(i) for i in all_outfiles]
    out_matrix_true = all_full_out_matrices[0].separate_output()[0]
    all_out_matrices = [i.separate_output()[1] for i in all_full_out_matrices]
    
    #read_predictions = S.vstack(all_out_matrices)
    #read_predictions[read_predictions > 1.0] = 1.0
    
    #print("READ ", len(read_predictions))
    return all_out_matrices, out_matrix_true
#
#
#
def _load_samples_new(basedir_ls,munge="*.out"):
    all_outfiles = _glob.glob(os.path.join(basedir_ls, munge))
    all_outfiles.sort()
    #print all_outfiles
    
    all_full_out_matrices = [GEMSTAT_Matrix.load(i) for i in all_outfiles]
    
    #read_predictions = S.vstack(all_out_matrices)
    #read_predictions[read_predictions > 1.0] = 1.0
    
    #print("READ ", len(read_predictions))
    return all_full_out_matrices
 
def create_generator(basedir,orthologs_to_use=None):
    
    settings_contents = ""
    with open(os.path.join(basedir,"SETTINGS_2.bash")) as settings_file:
        settings_contents = settings_file.read().strip()
    
    #detect if this is an old or new style job
    old_style_job = False
    job_methods = list()
    detected_orthonames = list()
    
    #Test for old style job
    if len(_glob.glob(os.path.join(basedir,"crossval","*_*_expanded.out"))) != 0:
        old_style_job = True
        detected_orthonames = list(set([_re.sub(".*_([^_]*)_.*","\\1",i) for i in os.listdir(os.path.join(basedir,"crossval")) ]))
        job_methods = ["std","reg"]
    else:#new style job
        old_style_job = False
        find_m_names = _re.findall("""method_names[:whitespace:]*=[:whitespace:]*("|')(.*)("|')""",settings_contents)
        job_methods = map(lambda x:x.strip(), find_m_names[-1][1].split())
        detected_orthonames = list(set([_re.sub("([^_]*)_\d*.out","\\1",i) for i in os.listdir(os.path.join(basedir,
                                                                                                         "samples",
                                                                                                         "method_{}".format(job_methods[0])
                                                                                                         ,"crossval")) ]))
    def generate_data_oldstyle(basedir_gdo,job_methods,generator_ortho_names_to_use):
        for one_ortho in generator_ortho_names_to_use:
            #Read all predictions
            read_predictions , out_matrix_true  = _load_samples(os.path.join(basedir_gdo,"crossval"),munge="*_" + one_ortho + "_raw.out")
            read_predictions2, out_matrix_true2 = _load_samples(os.path.join(basedir_gdo,"crossval"),munge="*_" + one_ortho + "_expanded.out")
            yield one_ortho, {"std":(out_matrix_true,read_predictions),"reg":(out_matrix_true2,read_predictions2)}
    
    def generate_data_newstyle(basedir_gdn,job_methods,generator_ortho_names_to_use):
        for one_ortho in generator_ortho_names_to_use:
            gt_filename = os.path.join(basedir_gdn,"data","ORTHO",one_ortho,"expr.tab")
	    if not os.path.isfile(gt_filename):
		gt_filename = os.path.join(basedir_gdn,"data","base","expr.tab")
		if not os.path.isfile(gt_filename):
			raise Exception("Could not find ground truth.")
            ground_truth = GEMSTAT_Matrix.load(os.path.join(gt_filename))
            ret_dict = dict()
            for one_method in job_methods:
                read_pred = _load_samples_new(os.path.join(basedir_gdn,"samples/method_{}/crossval".format(one_method)),
                                                  munge=one_ortho+"_*.out")
                read_pred = [i if i.storage.shape[0] == ground_truth.storage.shape[0] else i.separate_output()[1] for i in read_pred]
                ret_dict[one_method] = (ground_truth,read_pred)
            yield one_ortho, ret_dict
    
    the_generator = None
    if old_style_job:
        the_generator = generate_data_oldstyle(basedir,job_methods,orthologs_to_use if orthologs_to_use is not None else detected_orthonames)
    else:
        the_generator = generate_data_newstyle(basedir,job_methods,orthologs_to_use if orthologs_to_use is not None else detected_orthonames)
    final_return_dictionary = {"old_style_job":old_style_job,
                               "job_methods":job_methods,
                                "loaded_orthonames":orthologs_to_use if orthologs_to_use is not None else detected_orthonames,
                                "settings":settings_contents,
                               "generator":the_generator
                              }
    return final_return_dictionary
