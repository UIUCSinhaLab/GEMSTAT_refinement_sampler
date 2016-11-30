#!/bin/bash

#module load python
export PATH=/software/python-2.7.10-x86_64/bin:${PATH}

echo "USING PYTHON " $(which python)

LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH

#JOBBASE we get from the environment
#JOBID we also get from the environment, but it should just match job base
SCORING_METHODS=$(ls ${BASE}/SCORING)

source ${JOBBASE}/ENV_DUMP.txt
source ${JOBBASE}/SETTINGS_2.bash

#since it's just one overall scoring tool, it's ok to use copied data..., it will only get copied once, not for every score.

#this can be changed later if we decide we want to stage the data in
datadir_to_use=${JOBBASE}/data
tmpdatadir=$(mktemp -d ${TMP-${TMPDIR}}/${method_name}_temp_data.XXXXXX)
training_data_dir=${tmpdatadir}/training_data
mkdir -p ${training_data_dir}

cp ${datadir_to_use}/base/* ${training_data_dir}
cp ${datadir_to_use}/ORTHO/${TRAIN_ORTHO}/* ${training_data_dir} #TODO: Make conditional

##score that on every crossvalidation set
#copy/setup the crossvalidation data here to not repeat the work every time.
for ORTHO_DIR in ${datadir_to_use}/ORTHO/*
do
	ORTHO_NAME=$(basename ${ORTHO_DIR})
	
        mkdir -p ${tmpdatadir}/ORTHO_${ORTHO_NAME}
        cp ${datadir_to_use}/base/* ${tmpdatadir}/ORTHO_${ORTHO_NAME}/
        cp ${ORTHO_DIR}/* ${tmpdatadir}/ORTHO_${ORTHO_NAME}/
done



for method_name in ${method_names}
do
	method_sample_dir=${JOBBASE}/samples/method_${method_name}/


	##score that on every crossvalidation set
	for ORTHO_DIR in ${datadir_to_use}/ORTHO/*
	do
		ORTHO_NAME=$(basename ${ORTHO_DIR})
		ORTHO_DATA_DIR=${tmpdatadir}/ORTHO_${ORTHO_NAME}
		
		METHOD_ORTHO_SCORE_FILE=${JOBBASE}/scores/${method_name}.txt
		echo -n '#i' > ${METHOD_ORTHO_SCORE_FILE}
		for one_scoring_method in ${SCORING_METHODS}
		do
			echo -n " ${one_scoring_method}" >> ${METHOD_ORTHO_SCORE_FILE}
		done
		echo "" >> ${METHOD_ORTHO_SCORE_FILE}
		
		#for every refined par file	
		for N in $(seq ${N_TO_REFINE})
		do
		#
		#Call the prediction method
		#
		
		echo -n "$N" >> ${METHOD_ORTHO_SCORE_FILE}


			for one_scoring_method in ${SCORING_METHODS}
			do
				echo -n " " >> ${METHOD_ORTHO_SCORE_FILE}
				echo -n "$(${BASE}/SCORING/${one_scoring_method} --data ${tmpdatadir}/ORTHO_${ORTHO_NAME} --parfile ${JOBBASE}/par/${N}.par --parout ${method_sample_dir}/out/${N}.par --out ${method_sample_dir}/out/${N}.out)" >> ${METHOD_ORTHO_SCORE_FILE}
			done
			
			echo "" >> ${METHOD_ORTHO_SCORE_FILE}
		done
	done

done
