#!/bin/bash

set -e

LANGS=$1
shift
PREFIX=$1
shift
GPUS=$@

DATA=./data
MARIAN=../tools/marian-dev/build
MODEL=./models/$LANGS

tee $PREFIX.in | $MARIAN/marian-decoder -c $MODEL.ens/ensemble.yml -d $GPUS --n-best --mini-batch 64 --maxi-batch 1000 --maxi-batch-sort src --quiet -w 4000 > $PREFIX.nbest.0

N=2
for i in `seq $N`; do
    $MARIAN/marian-scorer -d $GPUS \
        -m $MODEL.r2l.$i/model.npz.best-translation.npz \
        -t $PREFIX.in $PREFIX.nbest.$(expr $i - 1) \
        -v $MODEL.ens/vocab.yml $MODEL.ens/vocab.yml \
        --mini-batch 100 --maxi-batch 1000 --maxi-batch-sort trg --quiet --n-best --n-best-feature R2L$i \
        > $PREFIX.nbest.$i
done

cat $PREFIX.nbest.$N | python ../tools/rescore.py
