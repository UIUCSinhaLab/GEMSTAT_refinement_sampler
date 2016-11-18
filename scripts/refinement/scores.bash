#!/bin/bash


#module load python
export PATH=/software/python-2.7.10-x86_64/bin:${PATH}

echo "USING PYTHON " $(which python)

LD_LIBRARY_PATH=~/usr/lib:/home/grad/samee1/packages/gsl-1.14/lib:/software/intel-composer-2011u5-x86_64/composerxe-2011.5.220/mkl/lib/intel64:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH

set -e

export BASE=${BASE-"."}
export SRC=${SRC-"$BASE/GEMBASE/src"}

export JOBBASE=${JOBBASE-"${BASE}"}
export DATA=${JOBBASE}/data
export OUTFILE=${OUTFILE-"ind_model.out"}
export PAR_DIR=${PAR_DIR-"$JOBBASE/par"}
export LOG=${BUILD_LOG-"$JOBBASE/log"}
export OUT=${BUILD_OUT-"$JOBBASE/out"}

export CROSSVAL_DIR=${JOBBASE}/crossval


#compile the results later

for PARFILE in ${JOBBASE}/par/*.par
do
	SINGLE_PAR_FILE=$(basename ${PARFILE} .par)	
        read aa raw_beta raw_score < ${LOG}/${SINGLE_PAR_FILE}_raw.log
        read aa exp_beta exp_score < ${LOG}/${SINGLE_PAR_FILE}_expanded.log
	
        echo "${raw_beta} ${raw_score} ${exp_beta} ${exp_score} ${SINGLE_PAR_FILE}" >> ${JOBBASE}/refined_scores.txt
	
	for ORTHO_SEQ in ${DATA}/ORTHO/*.fa
	do
		#prevent stale outputs
                rm -f ${LOG}/${SINGLE_PAR_FILE}_raw.log ${LOG}/${SINGLE_PAR_FILE}_expanded.log
                ORTHO_NAME=$(basename ${ORTHO_SEQ} .fa)
		
		read aa raw_beta raw_score < ${LOG}/${SINGLE_PAR_FILE}_${ORTHO_NAME}_raw.log
                read aa exp_beta exp_score < ${LOG}/${SINGLE_PAR_FILE}_${ORTHO_NAME}_expanded.log
                
                echo "${raw_beta} ${raw_score} ${exp_beta} ${exp_score} ${SINGLE_PAR_FILE}" >> ${JOBBASE}/refined_scores_${ORTHO_NAME}.txt
	done
done

for ORTHO_SEQ in ${DATA}/ORTHO/*.fa
do
	name=$(basename ${ORTHO_SEQ} .fa)
	python -c "import scipy as S; A = S.loadtxt('${JOBBASE}/refined_scores_${name}.txt'); foo = A[:,1].mean() - A[:,3].mean(); print '${name} %.15f' % foo;" >> ${JOBBASE}/final_scores.txt
done	
	
#this is just TEMPORARY for the ensemble sampling
#FULL, UNSMOOTHED DATA
