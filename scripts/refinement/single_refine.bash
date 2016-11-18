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

PARFILE="$1/par/${N}.par"
SINGLE_PAR_FILE=$(basename ${PARFILE} .par)
STARTING_POINT_ARGS="-p ${PARFILE}"

#Normal refinement	
$SRC/seq2expr ${COMMON_DATA_ARGS} ${MODEL_ARGS} ${EXTRA_CMD_RAW} -wt ${DATA}/axis_wts.txt -e $DATA/expr_raw.tab -f $DATA/factor_expr_raw.tab -fo ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_raw.out -na ${NA_SMOOTH} ${STARTING_POINT_ARGS} -po ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_raw.par | tail -n1 > ${LOG}/${SINGLE_PAR_FILE}_raw.log

#robustness refinement, we discard the score because there are more conditions.
$SRC/seq2expr ${COMMON_DATA_ARGS} ${MODEL_ARGS} ${EXTRA_CMD_ROBUST_TRAIN} -wt ${DATA}/axis_wts_expanded.txt -e $DATA/expr_expanded.tab -f $DATA/factor_expr_expanded.tab -fo /dev/null -na ${NA_NOSMOOTH} ${STARTING_POINT_ARGS} -po ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_expanded.par > /dev/null
#get a score for the robustness refinement on the same data as the normal refinement. Expected to be worse, but we still want them to be comparable.
$SRC/seq2expr ${COMMON_DATA_ARGS} ${MODEL_ARGS} ${EXTRA_CMD_ROBUST_TEST} -wt ${DATA}/axis_wts.txt -e $DATA/expr_raw.tab -f $DATA/factor_expr_raw.tab -fo ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_expanded.out -na 0 -p ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_expanded.par | tail -n1 > ${LOG}/${SINGLE_PAR_FILE}_expanded.log

##score that on every ortholog	
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
	
	
	$SRC/seq2expr ${COMMON_DATA_ARGS} -s ${ORTHO_SEQ} ${MODEL_ARGS} ${EXTRA_CMD_RAW} -wt ${DATA}/axis_wts.txt -e ${ORTHO_EXPR} -f $DATA/factor_expr_raw.tab -fo /dev/null -na 0 -p ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_raw.par -fo ${CROSSVAL_DIR}/${SINGLE_PAR_FILE}_${ORTHO_NAME}_raw.out | tail -n1 > ${LOG}/${SINGLE_PAR_FILE}_${ORTHO_NAME}_raw.log
	$SRC/seq2expr ${COMMON_DATA_ARGS} -s ${ORTHO_SEQ} ${MODEL_ARGS} ${EXTRA_CMD_ROBUST_TEST} -wt ${DATA}/axis_wts.txt -e ${ORTHO_EXPR} -f $DATA/factor_expr_raw.tab -fo /dev/null -na 0 -p ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_expanded.par  -fo ${CROSSVAL_DIR}/${SINGLE_PAR_FILE}_${ORTHO_NAME}_expanded.out | tail -n1 > ${LOG}/${SINGLE_PAR_FILE}_${ORTHO_NAME}_expanded.log
done
