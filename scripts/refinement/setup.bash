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

echo JOBID ${JOBID} JOBBASE ${JOBBASE}


export CROSSVAL_DIR=${JOBBASE}/crossval
mkdir -p ${CROSSVAL_DIR}

#export BASE_COMMON_ARGS="-rs $DATA/r_seqs.fa -m $DATA/factors.wtmx -i ${DATA}/factor_info.txt -c $DATA/coop.txt -ff $DATA/free_fix.ensemb_refine.txt"
export BASE_COMMON_ARGS=" -m $DATA/factors.wtmx -i ${DATA}/factor_info.txt -c $DATA/coop.txt -ff $DATA/free_fix.ensemb_refine.txt"
export COMMON_DATA_ARGS="-s $DATA/seqs_ind.fa ${BASE_COMMON_ARGS}"
export MODEL_ARGS="-o Direct -oo SSE -ct 25 -rt 250 -et 0.5 "


#HASSAN DATA
export NA_SMOOTH=${NA_SMOOTH-"5"}
export NA_NOSMOOTH=${NA_NOSMOOTH-"5"}
N_TO_REFINE=100
export DATA_ORIGIN="data_hassan_cic_baked"
COPIES=2
SIGMA0=0.0
SIGMA1=0.15
SIGMA0_EXPR=0.0
SIGMA1_EXPR=0.0
ALPHA=0.5
ROBUSTNESS_OTHER=""
ROBUSTNESS_OTHER_EXPR=""
PREP_EXPR_CMD="cp"
#FILTERED_MODEL_SOURCE="filtered_models/RAND_ENSEMBLE/"
SEED=667

if [ -f "REFINEMENT_SETTINGS/${JOBID}.bash" ]
then
	cp "REFINEMENT_SETTINGS/${JOBID}.bash" ${JOBBASE}/SETTINGS_2.bash
	source ${JOBBASE}/SETTINGS_2.bash
fi

if [ -d ${DATA_ORIGIN} ]
then
	cp -r ${DATA_ORIGIN}/* ${DATA}/
elif [ -d ${BASE}/data_for_experiments/${DATA_ORIGIN} ]
then
	export DATA_ORIGIN=${BASE}/data_for_experiments/${DATA_ORIGIN}
	cp -r ${DATA_ORIGIN}/* ${DATA}/
else
	echo "Could not find data origin"
	exit 1
fi	

cp ${DATA}/factor_expr.tab $DATA/factor_expr_raw.tab
cp ${DATA}/expr.tab $DATA/expr_raw.tab
#cp ${DATA}/dperk.tab $DATA/dperk_raw.tab

python pysrc/make_robustness_input.py --s0 ${SIGMA0} --s1 ${SIGMA1} ${ROBUSTNESS_OTHER} --C ${COPIES} -- ${DATA}/factor_expr_raw.tab $DATA/factor_expr_expanded.tab

export EXTRA_CMD_ROBUST_TRAIN=" ${EXTRA_CMD_ROBUST} "
export EXTRA_CMD_ROBUST_TEST=" ${EXTRA_CMD_ROBUST} "

if [ -f "${DATA}/dperk.tab" ]
then
	cp ${DATA}/dperk.tab $DATA/dperk_raw.tab
	python pysrc/make_robustness_input.py --s0 ${DPSIG0-"$SIGMA0"} --s1 ${DPSIG2-"$SIGMA1"} ${ROBUSTNESS_OTHER} --C ${COPIES} -- ${DATA}/dperk_raw.tab $DATA/dperk_expanded.tab
	export EXTRA_CMD_RAW=" ${EXTRA_CMD_RAW} -dp ${DATA}/dperk_raw.tab "
	export EXTRA_CMD_ROBUST_TRAIN=" ${EXTRA_CMD_ROBUST} -dp ${DATA}/dperk_expanded.tab "
	export EXTRA_CMD_ROBUST_TEST=" ${EXTRA_CMD_ROBUST} -dp ${DATA}/dperk_raw.tab "
fi

python pysrc/make_robustness_input.py --s0 ${SIGMA0_EXPR} --s1 ${SIGMA1_EXPR} ${ROBUSTNESS_OTHER_EXPR} --C ${COPIES} -- ${DATA}/expr_raw.tab $DATA/expr_expanded.tab
python pysrc/copy_axis_wts.py -C ${COPIES} --alpha ${ALPHA} ${DATA}/axis_wts.txt ${DATA}/axis_wts_expanded.txt

#copy PAR files in
if [ -z "${FILTERED_MODEL_SOURCE}" ]
then
	python pysrc/par_template_processor.py --seed ${SEED} --N ${N_TO_REFINE} --outpre ${JOBBASE}/par/ ${DATA}/template.par
else
	for N in $(seq ${N_TO_REFINE})	
	do
		cp ${FILTERED_MODEL_SOURCE}/${N}.par ${PAR_DIR}/${N}.par
	done
fi

export > ${JOBBASE}/ENV_DUMP.txt
