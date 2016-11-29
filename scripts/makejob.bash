#!/bin/bash



JOBID=$1

PARENTDIR=${2-'./JOBS/'}

if [ ! -d ${PARENTDIR} ]
then
	echo "Parent directory does not exist"
	exit 1
fi



JOBDIR=${PARENTDIR}/${JOBID}

mkdir -p ${JOBDIR}
mkdir -p ${JOBDIR}/samples

#for method_number in 1 2
#do
#	mkdir -p ${JOBDIR}/samples/method_${method_number}
#	mkdir -p ${JOBDIR}/samples/method_${method_number}/out
#	mkdir -p ${JOBDIR}/samples/method_${method_number}/log
#	mkdir -p ${JOBDIR}/samples/method_${method_number}/data
#done

mkdir -p ${JOBDIR}/par
mkdir -p ${JOBDIR}/log
mkdir -p ${JOBDIR}/out
mkdir -p ${JOBDIR}/data

mkdir -p ${JOBDIR}/other

#cp data/* ${JOBDIR}/data

#cat > ${JOBDIR}/SETTINGS.bash << EOF
#export JOBBASE=${PARENTDIR}/${JOBID}
#export PAR_DIR=\${JOBBASE}/par
#export BUILD_LOG=\${JOBBASE}/log
#export BUILD_OUT=\${JOBBASE}/out
#export DATA=\${JOBBASE}/data
#EOF

echo ${JOBDIR}
