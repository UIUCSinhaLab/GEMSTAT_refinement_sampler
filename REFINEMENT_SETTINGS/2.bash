

method_names="EXAMPLE new"

TRAIN_ORTHO=mel

N_TO_REFINE=10
#ENSEMBLE_NAME="example_ensemble" demonstrates randomly sampling from a template.

DATA_ORIGIN="data_hassan_cic_baked_zld_free"


#any environment variables we exported will be available to the method
export NA_CYCLES=2

#Other environment variables provided to the method script
method_environment_EXAMPLE="NA_CYCLES=5"
method_environment_new="NA_CYCLES=2 COPIES=20 SIGMA0=0.05 SIGMA1=0.0"

#Other command-line parameters provided to the method script after a -- 
method_args_EXAMPLE="some_additional arguments"
method_args_new=""
