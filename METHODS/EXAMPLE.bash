#1/bin/bash

#!/bin/bash
#
# from stackoverflow.com : http://stackoverflow.com/a/14203146
#
# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )

#expected from environment
#DATA
#JOBBASE
#N job number
#Whatever was in your settings file.



#Default values
TRAIN=0


while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -t|--train)
    TRAIN=1
    ;;
    -d|--data)
    DATA="$2"
    shift # past argument
    ;;
    -l|--log)
    LOG="$2"
    shift # past argument
    ;;
    -o|--out)
    OUT_prefix="$2"
    shift
    ;;
    -p|--parfile)
    PARFILE="$2"
    shift
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done
echo FILE EXTENSION  = "${EXTENSION}"
echo SEARCH PATH     = "${SEARCHPATH}"
echo LIBRARY PATH    = "${LIBPATH}"

#use whatever way you want to separate training from prediction
if [ ! $TRAIN == "1" ]
then
	NA_CYCLES=0
fi

SINGLE_PAR_FILE=$(basename ${PARFILE} .par)
STARTING_POINT_ARGS="-p ${PARFILE}"


#export BASE_COMMON_ARGS="-rs $DATA/r_seqs.fa -m $DATA/factors.wtmx -i ${DATA}/factor_info.txt -c $DATA/coop.txt -ff $DATA/free_fix.ensemb_refine.txt"
export BASE_COMMON_ARGS=" -m $DATA/factors.wtmx -i ${DATA}/factor_info.txt -c $DATA/coop.txt -ff $DATA/free_fix.ensemb_refine.txt"
export COMMON_DATA_ARGS="-s $DATA/seqs.fa ${BASE_COMMON_ARGS}"
export MODEL_ARGS="-o Direct -oo SSE -ct 25 -rt 250 -et 0.5 "



$SRC/seq2expr ${COMMON_DATA_ARGS} ${MODEL_ARGS} -e $DATA/expr.tab -f $DATA/factor_expr.tab -fo ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_raw.out -na ${NA_SMOOTH} ${STARTING_POINT_ARGS} -po ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_raw.par | tail -n1 > ${LOG}/${SINGLE_PAR_FILE}_raw.log	


$SRC/seq2expr ${COMMON_DATA_ARGS} -s ${ORTHO_SEQ} ${MODEL_ARGS} ${EXTRA_CMD_RAW} -wt ${DATA}/axis_wts.txt -e ${ORTHO_EXPR} -f $DATA/factor_expr_raw.tab -fo /dev/null -na 0 -p ${JOBBASE}/samples/out/${SINGLE_PAR_FILE}_raw.par -fo ${CROSSVAL_DIR}/${SINGLE_PAR_FILE}_${ORTHO_NAME}_raw.out | tail -n1 > ${LOG}/${SINGLE_PAR_FILE}_${ORTHO_NAME}_raw.log


