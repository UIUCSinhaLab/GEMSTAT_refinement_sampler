#!/bin/bash

#module load python
export PATH=/software/python-2.7.10-x86_64/bin:${PATH}

echo "USING PYTHON " $(which python)

LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH

JOBBASE=$1
N=$(( ${2} + 1 ))
method_name=${3}


source ${JOBBASE}/ENV_DUMP.txt
source ${JOBBASE}/SETTINGS_2.bash

export > ${JOBBASE}/final.bash


method_sample_dir=${JOBBASE}/samples/method_${method_name}/

#this can be changed later if we decide we want to stage the data in
datadir_to_use=${JOBBASE}/data

tmpdatadir=$(mktemp -d ${TMP-${TMPDIR}}/${method_name}_temp_data.XXXXXX)

training_data_dir=${tmpdatadir}/training_data
mkdir -p ${training_data_dir}

cp ${datadir_to_use}/base/* ${training_data_dir}
cp ${datadir_to_use}/ORTHO/${TRAIN_ORTHO}/* ${training_data_dir} #TODO: Make conditional


#
#Call the training method
#

#parenthesis so that the results of the eval don't come out into this shell.
(
#definitely not secure
eval 'method_additional_environment=${method_environment_'"${method_name}"'}'
eval 'method_additional_args=${method_args_'"${method_name}"'}'
eval ${method_additional_environment} ${BASE}/METHODS/${method_name} --train --data ${training_data_dir} --parfile ${JOBBASE}/par/${N}.par --log ${method_sample_dir}/log/${N}.log --out ${method_sample_dir}/out/${N}.out --parout ${method_sample_dir}/out/${N}.par -- ${method_additional_args}
)



##score that on every crossvalidation set
for ORTHO_DIR in ${datadir_to_use}/ORTHO/*
do
	ORTHO_NAME=$(basename ${ORTHO_DIR})
	
	mkdir -p ${tmpdatadir}/ORTHO_${ORTHO_NAME}
	cp ${datadir_to_use}/base/* ${tmpdatadir}/ORTHO_${ORTHO_NAME}/
	cp ${ORTHO_DIR}/* ${tmpdatadir}/ORTHO_${ORTHO_NAME}/
	
	#
	#Call the prediction method
	#
	(
	eval 'method_additional_environment=${method_environment_'"${method_name}"'}'
	eval 'method_additional_args=${method_args_'"${method_name}"'}'
	eval ${method_additional_environment} ${BASE}/METHODS/${method_name} --data ${tmpdatadir}/ORTHO_${ORTHO_NAME} --parfile ${method_sample_dir}/out/${N}.par --log ${method_sample_dir}/log/${ORTHO_NAME}_${N}.log --out ${method_sample_dir}/crossval/${ORTHO_NAME}_${N}.out -- ${method_additional_args}
	)
done


if [ "${DEBUG}" = "True" ]
then

	sleep 1000
fi
