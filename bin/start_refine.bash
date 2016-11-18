#!/bin/bash


SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=${SCRIPT_DIR}/..

JOB_ID=$1

source ${BASE_DIR}/REFINEMENT_SETTINGS/${JOB_ID}.bash

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

cat > ${JOBDIR}/other/refine.con << EOF
Universe       = vanilla
Executable     = ${BASE_DIR}/scripts/refinement/single_refine.bash

input   = /dev/null
output  = ${JOBDIR}/log/refine.out.\$(Process)
error   = ${JOBDIR}/log/refine.error.\$(Process)

environment = "BASE=${BASE_DIR} JOBBASE=${JOBDIR} JOBID=${JOB_ID}"

arguments = ${JOBDIR} \$(Process)
                                                  
Queue ${N_TO_REFINE}
EOF

cat > ${JOBDIR}/other/scores.con << EOF
Universe       = vanilla
Executable     = ${BASE_DIR}/scripts/refinement/scores.bash

input   = /dev/null
output  = ${JOBDIR}/log/scores.out.\$(Process)
error   = ${JOBDIR}/log/scores.error.\$(Process)

environment = "BASE=${BASE_DIR} JOBBASE=${JOBDIR} JOBID=${JOB_ID}"

Queue 1

EOF

cat > ${JOBDIR}/other/everything.dag << EOF
CONFIG ${JOBDIR}/other/dagman.config
JOB setup ${JOBDIR}/other/setup.con
JOB refine ${JOBDIR}/other/refine.con
JOB scores ${JOBDIR}/other/scores.con
PARENT setup CHILD refine
PARENT refine CHILD scores
EOF

cat > ${JOBDIR}/other/dagman.config << EOF
DAGMAN_LOG_ON_NFS_IS_ERROR = False
EOF

condor_submit_dag ${JOBDIR}/other/everything.dag
