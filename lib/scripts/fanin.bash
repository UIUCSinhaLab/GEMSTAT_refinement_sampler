#!/bin/bash

#module load python
export PATH=/software/python-2.7.10-x86_64/bin:${PATH}

echo "USING PYTHON " $(which python)

LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH



JOBBASE=$1
method_name=${2}
START_N=${3}
END_N=${4}


source ${JOBBASE}/ENV_DUMP.txt
source ${JOBBASE}/SETTINGS_2.bash

export > ${JOBBASE}/final.bash

#assume BASE exists

method_sample_dir=${JOBBASE}/samples/method_${method_name}/

#this can be changed later if we decide we want to stage the data in
datadir_to_use=${JOBBASE}/data

LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/shared-mounts/sinhas-storage1/INFRASTRUCTURE/HAL/JUPYTER/python/lib/
PYTHONPATH=${PYTHONPATH}:${BASE}/lib/GEMSTAT_scripts/python/src/

PYTHONPATH=${PYTHONPATH} python ${BASE}/lib/python/sampling_core/fanin.py ${JOBBASE}/crossval/${method_name}.hd5 ${method_sample_dir} $(seq ${START_N} ${END_N})