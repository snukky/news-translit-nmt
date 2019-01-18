#!/bin/bash -v

set -e

GPUS=$1
shift
LANGSLIST=$@

DATA=./data
MARIAN=../tools/marian-dev/build

for langs in $LANGSLIST; do
    # Train NMT models
    for i in 1 2 3 4; do
        bash train-model.sh $langs $i $GPUS
    done

    # Train right-left NMT models
    for i in 1 2; do
        bash train-model.sh $langs r2l.$i $GPUS --right-left
    done

    # Build ensembles
    bash ensemble.sh $langs $GPUS
done
