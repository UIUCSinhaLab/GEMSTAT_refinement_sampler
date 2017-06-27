#!/bin/bash


SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=${SCRIPT_DIR}/..

JOB_ID=$1

JOBDIR=${BASE_DIR}/ENSEMBLE_REFINE/${JOB_ID}

if [ -f "${JOBDIR}/other/everything.dag.lock" ]
then
	echo "It appears that the job is still running."
	echo "If this is not the case, you must remove ${JOBDIR}/other/everything.dag.lock and try again."
	exit 1
fi	

condor_submit_dag ${JOBDIR}/other/everything.dag
