#!/bin/bash

set -e

LANGS=$1
shift
GPUS=$1
shift

DATA=./data
MARIAN=../tools/marian-dev/build
MODEL=./models/$LANGS


##############################################################################
echo "Preparing $MODEL.ens"
mkdir -p $MODEL.ens
cp $MODEL.1/vocab.yml $MODEL.ens/

models="  - $MODEL.1/model.npz.best-translation.npz\n  - $MODEL.2/model.npz.best-translation.npz\n  - $MODEL.3/model.npz.best-translation.npz\n  - $MODEL.4/model.npz.best-translation.npz"
cat $MODEL.1/model.npz.decoder.yml | sed -r -e "s|.*model.npz|$models|" -e "s|\.1/vocab|.ens/vocab|" > $MODEL.ens/ensemble.yml

test -s $MODEL.ens/eval.xml || cat ./data/$LANGS.dev.xml \
    | ../tools/extract-xml.py --source-only \
    | ../tools/tokenize.py \
    | $MARIAN/marian-decoder -c $MODEL.ens/ensemble.yml -d $GPUS -b 10 -n 1.0 --n-best --mini-batch 64 --maxi-batch 10 --maxi-batch-sort src --quiet \
    | tee $MODEL.ens/eval.nbest \
    | ../tools/detokenize.py \
    | ../tools/wrapper_xml.py <( ../tools/detokenize.py < ./data/$LANGS.dev.src ) --n-best \
    > $MODEL.ens/eval.xml

python ../tools/news_evaluation.py -i $MODEL.ens/eval.xml -t ./data/$LANGS.dev.xml -o $MODEL.ens/eval.csv \
    | tee $MODEL.ens/eval.txt


##############################################################################
echo "Preparing $MODEL.ens.r2l"
mkdir -p $MODEL.ens.r2l
cp $MODEL.1/vocab.yml $MODEL.ens.r2l/

models="  - $MODEL.r2l.1/model.npz.best-translation.npz\n  - $MODEL.r2l.2/model.npz.best-translation.npz"
cat $MODEL.1/model.npz.decoder.yml | sed -r -e "s|.*model.npz|$models|" -e "s|\.1/vocab|.ens.r2l/vocab|" > $MODEL.ens.r2l/ensemble.yml

test -s $MODEL.ens.r2l/eval.xml || cat ./data/$LANGS.dev.xml \
    | ../tools/extract-xml.py --source-only \
    | ../tools/tokenize.py \
    | $MARIAN/marian-decoder -c $MODEL.ens.r2l/ensemble.yml -d $GPUS -b 10 -n 1.0 --n-best --mini-batch 64 --maxi-batch 10 --maxi-batch-sort src --quiet \
    | tee $MODEL.ens.r2l/eval.nbest \
    | ../tools/detokenize.py \
    | ../tools/wrapper_xml.py <( ../tools/detokenize.py < ./data/$LANGS.dev.src ) --n-best \
    > $MODEL.ens.r2l/eval.xml

python ../tools/news_evaluation.py -i $MODEL.ens.r2l/eval.xml -t ./data/$LANGS.dev.xml -o $MODEL.ens.r2l/eval.csv \
    | tee $MODEL.ens.r2l/eval.txt


##############################################################################
echo "Preparing $MODEL.ens.r2l.rescore"
mkdir -p $MODEL.ens.r2l.rescore

cp $MODEL.ens/eval.nbest $MODEL.ens.r2l.rescore/eval.nbest.0

N=2

for i in `seq $N`
do
    test -s $MODEL.ens.r2l.rescore/eval.nbest.$i || $MARIAN/marian-scorer -d $GPUS \
        -m $MODEL.r2l.$i/model.npz.best-translation.npz \
        -t ./data/$LANGS.dev.src $MODEL.ens.r2l.rescore/eval.nbest.$(expr $i - 1) \
        -v $MODEL.ens/vocab.yml $MODEL.ens/vocab.yml \
            --mini-batch 64 --maxi-batch 10 --maxi-batch-sort trg --quiet --n-best --n-best-feature R2L$i \
        > $MODEL.ens.r2l.rescore/eval.nbest.$i
done

test -s $MODEL.ens.r2l.rescore/eval.out || cat $MODEL.ens.r2l.rescore/eval.nbest.$N \
    | python ../tools/rescore.py > $MODEL.ens.r2l.rescore/eval.out

test -s $MODEL.ens.r2l.rescore/eval.xml || cat $MODEL.ens.r2l.rescore/eval.nbest.$N \
    | python ../tools/rescore.py --n-best --normalize 1.0 \
    | tee $MODEL.ens.r2l.rescore/eval.nbest \
    | ../tools/detokenize.py \
    | ../tools/wrapper_xml.py <( ../tools/detokenize.py < ./data/$LANGS.dev.src ) --n-best \
    > $MODEL.ens.r2l.rescore/eval.xml

python ../tools/news_evaluation.py -i $MODEL.ens.r2l.rescore/eval.xml -t ./data/$LANGS.dev.xml -o $MODEL.ens.r2l.rescore/eval.csv \
    | tee $MODEL.ens.r2l.rescore/eval.txt
