#!/bin/bash


#module load python
export PATH=/software/python-2.7.10-x86_64/bin:${PATH}

echo "USING PYTHON " $(which python)

LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH

set -e

export BASE=${BASE-"."}
export JOBBASE=${JOBBASE-"${BASE}"}
export DATA=${JOBBASE}/data
export PAR_DIR=${PAR_DIR-"$JOBBASE/par"}
export LOG=${BUILD_LOG-"$JOBBASE/log"}
export OUT=${BUILD_OUT-"$JOBBASE/out"}

echo JOBID ${JOBID} JOBBASE ${JOBBASE}


export CROSSVAL_DIR=${JOBBASE}/crossval
mkdir -p ${CROSSVAL_DIR}

N_TO_REFINE=100
SEED=667

if [ -f "REFINEMENT_SETTINGS/${JOBID}.bash" ]
then
	cp "REFINEMENT_SETTINGS/${JOBID}.bash" ${JOBBASE}/SETTINGS_2.bash
	source ${JOBBASE}/SETTINGS_2.bash
fi

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
if [ -z "${FILTERED_MODEL_SOURCE}" ]
then
	python pysrc/par_template_processor.py --seed ${SEED} --N ${N_TO_REFINE} --outpre ${JOBBASE}/par/ ${DATA}/template.par
else
	for N in $(seq ${N_TO_REFINE})	
	do
		cp ${FILTERED_MODEL_SOURCE}/${N}.par ${PAR_DIR}/${N}.par
	done
fi

export > ${JOBBASE}/ENV_DUMP.txt
