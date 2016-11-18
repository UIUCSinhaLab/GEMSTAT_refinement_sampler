#!/bin/bash

#module load python
export PATH=/software/python-2.7.10-x86_64/bin:${PATH}

echo "USING PYTHON " $(which python)

LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH

JOBBASE=$1

source ${JOBBASE}/ENV_DUMP.txt
source ${JOBBASE}/SETTINGS_2.bash

N=$(( ${2} + 1 ))


#
#Call the training method
#
${BASE}/METHODS/${method_name} --train

##score that on every crossvalidation set
for ORTHO_SEQ in ${DATA}/ORTHO/*.fa
do
	#prevent stale outputs
	ORTHO_NAME=$(basename ${ORTHO_SEQ} .fa)
	
	#In case there is a different expression file for the ortholog.
	ORTHO_EXPR="$DATA/expr_raw.tab"
	if [ -f ${DATA}/ORTHO/${ORTHO_NAME}.tab ]
	then
		ORTHO_EXPR=${DATA}/ORTHO/${ORTHO_NAME}.tab
	fi
	
	#
	#Call the prediction method
	#
	
done
