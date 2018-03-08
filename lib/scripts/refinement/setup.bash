#!/bin/bash


#module load python
export PATH=/software/python-2.7.10-x86_64/bin:${PATH}

echo "USING PYTHON " $(which python)

LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH

set -e


#
# Overall DEFAULTS
#
export BASE=${BASE-"."}
export JOBBASE=${JOBBASE-"${BASE}"}
export DATA=${JOBBASE}/data
export PAR_DIR=${PAR_DIR-"$JOBBASE/par"}
export LOG=${BUILD_LOG-"$JOBBASE/log"}
export OUT=${BUILD_OUT-"$JOBBASE/out"}

echo JOBID ${JOBID} JOBBASE ${JOBBASE}

mkdir -p ${JOBBASE}/scores

export CROSSVAL_DIR=${JOBBASE}/crossval
mkdir -p ${CROSSVAL_DIR}

N_TO_REFINE=100
SEED=667

if [ -f "REFINEMENT_SETTINGS/${JOBID}.bash" ]
then
	cp "REFINEMENT_SETTINGS/${JOBID}.bash" ${JOBBASE}/SETTINGS_2.bash
	source ${JOBBASE}/SETTINGS_2.bash
fi

# Create necesary subdirectories
for one_method_name in ${method_names}
do
	mkdir -p ${JOBBASE}/samples/method_${one_method_name}/crossval
	mkdir -p ${JOBBASE}/samples/method_${one_method_name}/out
	mkdir -p ${JOBBASE}/samples/method_${one_method_name}/log
	mkdir -p ${JOBBASE}/samples/method_${one_method_name}/data
done


if [ -d ${DATA_ORIGIN} ]
then
	cp -r ${DATA_ORIGIN}/* ${DATA}/
elif [ -d ${BASE}/data_for_experiments/${DATA_ORIGIN} ]
then
	export DATA_ORIGIN=${BASE}/data_for_experiments/${DATA_ORIGIN}
	cp -r ${DATA_ORIGIN}/* ${DATA}/
else
	echo "Could not find data origin"
	exit 1
fi	

#copy PAR files in
if [ -z "${ENSEMBLE_NAME}" ]
then
	TEMPLATE_FILENAME="template.par"
	if [ -z ${TEMPLATE_NAME} ]
	then
		#nothing
		echo "No special template name provided."
	else
		TEMPLATE_FILENAME=${TEMPLATE_NAME}
	fi
	
	python ${BASE}/lib/python/sampling_core/par_template_processor.py --seed ${SEED} --N ${N_TO_REFINE} --outpre ${PAR_DIR}/ ${DATA}/${TEMPLATE_FILENAME}
else
	for N in $(seq ${N_TO_REFINE})	
	do
		cp ${BASE}/ENSEMBLES/${ENSEMBLE_NAME}/${N}.par ${PAR_DIR}/${N}.par
	done
fi

export | grep -e " BASE=" -e " JOBBASE=" -e " DATA=" -e " CROSSVAL_DIR=" -e " DATA=" -e " DATA_ORIGIN=" -e " JOBID=" -e " LOG=" -e " LD_LIBRARY_PATH=" -e " PATH=" -e " PAR_DIR=" > ${JOBBASE}/ENV_DUMP.txt
