#!/bin/bash

#module load python
export PATH=/software/python-2.7.10-x86_64/bin:${PATH}

echo "USING PYTHON " $(which python)

LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH

JOBBASE=$1
#N=$(( ${2} + 1 ))
N=${2}
method_name=${3}


source ${JOBBASE}/ENV_DUMP.txt
source ${JOBBASE}/SETTINGS_2.bash

export > ${JOBBASE}/final_singlecrossval.bash

cd ${BASE}


method_sample_dir=${JOBBASE}/samples/method_${method_name}/

#this can be changed later if we decide we want to stage the data in
datadir_to_use=${JOBBASE}/data

tmpdatadir=$(mktemp -d ${TMP-${TMPDIR}}/${method_name}_temp_data.XXXXXX)

training_data_dir=${tmpdatadir}/training_data
mkdir -p ${training_data_dir}

cp ${datadir_to_use}/base/* ${training_data_dir}
cp ${datadir_to_use}/ORTHO/${TRAIN_ORTHO}/* ${training_data_dir} #TODO: Make conditional

TRAINED_PAR_FILE=${tmpdatadir}/trained_par_file.par

(
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/shared-mounts/sinhas-storage1/INFRASTRUCTURE/HAL/JUPYTER/python/lib/ PYTHONPATH=${PYTHONPATH}:${BASE}/lib/GEMSTAT_scripts/python/src/:${BASE}/lib/notebook_core/:${BASE}/lib/sampling_core/ python ${BASE}/lib/python/sampling_core/hdf5_par.py ${JOBBASE}/crossval/${method_name}.hd5 ${N} > ${TRAINED_PAR_FILE}
)

if [ -z "${CROSSVAL_ORTHOS}" ]
then
	CROSSVAL_ORTHOS=$(ls "${datadir_to_use}/ORTHO/" )
fi

##score that on every crossvalidation set
for ORTHO_NAME in ${CROSSVAL_ORTHOS}
do
	ORTHO_DIR="${datadir_to_use}/ORTHO/${ORTHO_NAME}"
	if [ -d "${ORTHO_DIR}" ]
	then
		echo "crossvalidating on ${ORTHO_NAME}"
	else
		echo "Asked for an ortholog that does not exist! ${ORTHO_NAME}"
		continue
	fi

	mkdir -p ${tmpdatadir}/ORTHO_${ORTHO_NAME}
	cp ${datadir_to_use}/base/* ${tmpdatadir}/ORTHO_${ORTHO_NAME}/
	cp ${ORTHO_DIR}/* ${tmpdatadir}/ORTHO_${ORTHO_NAME}/

	#
	#Call the prediction method
	#
	echo "Trying to send output to " $( readlink -f ${method_sample_dir}/crossval/${ORTHO_NAME}_${N}.out )

	(
	eval 'method_additional_environment=${method_environment_'"${method_name}"'}'
	eval 'method_additional_args=${method_args_'"${method_name}"'}'
	eval ${method_additional_environment} ${BASE}/METHODS/${method_name} --data ${tmpdatadir}/ORTHO_${ORTHO_NAME} --parfile ${TRAINED_PAR_FILE} --log ${method_sample_dir}/log/${ORTHO_NAME}_${N}.log --out ${method_sample_dir}/crossval/${ORTHO_NAME}_${N}.out -- ${method_additional_args}
	) && ( rm ${method_sample_dir}/log/${ORTHO_NAME}_${N}.log ; echo "Crossval on ${ORTHO_NAME} DONE." ) || ( echo "Crossval on ${ORTHO_NAME} failed" )
done

echo "FINISHED"

if [ "${DEBUG}" = "True" ]
then
	echo "Stalling at end for debug"
	sleep 1000
fi
