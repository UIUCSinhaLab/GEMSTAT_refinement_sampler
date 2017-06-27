#!/bin/bash


SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=${SCRIPT_DIR}/..

JOB_ID=$1

if [ -f "${BASE_DIR}/REFINEMENT_SETTINGS/${JOB_ID}.bash" ]
then
	source ${BASE_DIR}/REFINEMENT_SETTINGS/${JOB_ID}.bash
else
	echo "you must provide the name of the job to run"
	exit 1
fi

pushd ${BASE_DIR}

JOBDIR=$(${BASE_DIR}/lib/scripts/makejob.bash ${JOB_ID} ENSEMBLE_REFINE)

cat > ${JOBDIR}/other/setup.con << EOF
Universe       = vanilla
Executable     = ${BASE_DIR}/lib/scripts/refinement/setup.bash

input   = /dev/null
output  = ${JOBDIR}/log/setup.out     
error   = ${JOBDIR}/log/setup.error

environment = "BASE=${BASE_DIR} JOBBASE=${JOBDIR} JOBID=${JOB_ID}"
                                           
Queue
EOF



cat > ${JOBDIR}/other/refine.con << EOF
Universe       = vanilla
Executable     = ${BASE_DIR}/lib/scripts/refinement/single_refine.bash


input   = /dev/null
output  = ${JOBDIR}/log/refine_\$(method_name).out.\$(whichitem)
error   = ${JOBDIR}/log/refine_\$(method_name).error.\$(whichitem)

environment = "BASE=${BASE_DIR} JOBBASE=${JOBDIR} JOBID=${JOB_ID}"

arguments = ${JOBDIR} \$(whichitem) \$(method_name)
                                                  
Queue 1
EOF


cat > ${JOBDIR}/other/scores.con << EOF
Universe       = vanilla
Executable     = ${BASE_DIR}/lib/scripts/refinement/scores.bash

input   = /dev/null
output  = ${JOBDIR}/log/scores.out.\$(Process)
error   = ${JOBDIR}/log/scores.error.\$(Process)

environment = "BASE=${BASE_DIR} JOBBASE=${JOBDIR} JOBID=${JOB_ID}"

arguments = ${JOBDIR} 

Queue 1

EOF

#
#CREATE the DAG
#

cat > ${JOBDIR}/other/everything.dag << EOF
CONFIG ${JOBDIR}/other/dagman.config
JOB setup ${JOBDIR}/other/setup.con
JOB scores ${JOBDIR}/other/scores.con
EOF

for one_method_name in ${method_names}
do

	for whichitem in $(seq 0 $((${N_TO_REFINE} - 1)))
	do
		cat >> ${JOBDIR}/other/refine_${one_method_name}.dag << EOF
JOB refine_${one_method_name}_${whichitem} ${JOBDIR}/other/refine.con
VARS refine_${one_method_name}_${whichitem} method_name="${one_method_name}"
VARS refine_${one_method_name}_${whichitem} whichitem="${whichitem}"
EOF
	done


cat >> ${JOBDIR}/other/everything.dag << EOF
SUBDAG EXTERNAL refine_${one_method_name} ${JOBDIR}/other/refine_${one_method_name}.dag
PARENT setup CHILD refine_${one_method_name}
PARENT refine_${one_method_name} CHILD scores
EOF

done



cat > ${JOBDIR}/other/dagman.config << EOF
DAGMAN_LOG_ON_NFS_IS_ERROR = False
EOF

condor_submit_dag -batch-name ${JOB_ID} ${JOBDIR}/other/everything.dag
