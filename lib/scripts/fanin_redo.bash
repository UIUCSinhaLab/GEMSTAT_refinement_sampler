#!/bin/bash


JOBBASE=$1
method_name=${2}
START_N=${3}
END_N=${4}

JOB_NAME=$(basename ${JOBBASE})

source ${JOBBASE}/ENV_DUMP.txt
source ${JOBBASE}/SETTINGS_2.bash

source /home/bjlunt2/.bashrc
source /home/bjlunt2/.profile
module load python/2.7.11
#module load python
#export PATH=/software/python-2.7.10-x86_64/bin:${PATH}
echo "USING PYTHON " $(which python)
#LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
#export LD_LIBRARY_PATH


#assume BASE exists

method_sample_dir=${BASE}/ENSEMBLE_REFINE/${JOB_NAME}/samples/method_${method_name}/


#this can be changed later if we decide we want to stage the data in
datadir_to_use=${JOBBASE}/data

LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/shared-mounts/sinhas-storage1/INFRASTRUCTURE/HAL/JUPYTER/python/lib/
PYTHONPATH=${PYTHONPATH}:${BASE}/lib/GEMSTAT_scripts/python/src/:${BASE}/lib/notebook_core/:${BASE}/lib/sampling_core/:


#Run the fanin script
pushd $TEMP
export > foobarbaz
echo unzip ${method_sample_dir}/zips/batch_${START_N}_${END_N}.zip >> commandline
echo PYTHONPATH=${PYTHONPATH} python ${BASE}/lib/python/sampling_core/fanin.py ${JOBBASE}/crossval/${method_name}.hd5 ${TEMP}/ENSEMBLE_REFINE/${JOB_NAME}/samples/method_${method_name}/ $(seq ${START_N} ${END_N}) >> commandline

unzip ${method_sample_dir}/zips/batch_${START_N}_${END_N}.zip 

popd

if [ "${START_N}" == "0" ]
then 
	mv ${JOBBASE}/crossval/${method_name}.hd5 ${JOBBASE}/crossval/${method_name}.hd5.back
fi

PYTHONPATH=${PYTHONPATH} python ${BASE}/lib/python/sampling_core/fanin.py ${JOBBASE}/crossval/${method_name}.hd5 ${TEMP}/ENSEMBLE_REFINE/${JOB_NAME}/samples/method_${method_name}/ $(seq ${START_N} ${END_N})

