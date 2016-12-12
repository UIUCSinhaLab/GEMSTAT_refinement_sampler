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

JOBDIR=$(./scripts/makejob.bash ${JOB_ID} ENSEMBLE_REFINE)

cat > ${JOBDIR}/other/setup.con << EOF
Universe       = vanilla
Executable     = ${BASE_DIR}/scripts/refinement/setup.bash

input   = /dev/null
output  = ${JOBDIR}/log/setup.out     
error   = ${JOBDIR}/log/setup.error

environment = "BASE=${BASE_DIR} JOBBASE=${JOBDIR} JOBID=${JOB_ID}"
                                           
Queue
EOF


for one_method_name in ${method_names}
do

	cat > ${JOBDIR}/other/refine_${one_method_name}.con << EOF
Universe       = vanilla
Executable     = ${BASE_DIR}/scripts/refinement/single_refine.bash


input   = /dev/null
output  = ${JOBDIR}/log/refine_${one_method_name}.out.\$(Process)
error   = ${JOBDIR}/log/refine_${one_method_name}.error.\$(Process)

environment = "BASE=${BASE_DIR} JOBBASE=${JOBDIR} JOBID=${JOB_ID}"

arguments = ${JOBDIR} \$(Process) ${one_method_name}
                                                  
Queue ${N_TO_REFINE}
EOF

done

cat > ${JOBDIR}/other/scores.con << EOF
Universe       = vanilla
Executable     = ${BASE_DIR}/scripts/refinement/scores.bash

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

	cat >> ${JOBDIR}/other/everything.dag << EOF
JOB refine_${one_method_name} ${JOBDIR}/other/refine_${one_method_name}.con
PARENT setup CHILD refine_${one_method_name}
PARENT refine_${one_method_name} CHILD scores
EOF

done

cat > ${JOBDIR}/other/dagman.config << EOF
DAGMAN_LOG_ON_NFS_IS_ERROR = False
EOF

condor_submit_dag ${JOBDIR}/other/everything.dag
