#!/bin/bash -v

set -e

LANGS=$1
shift
SRC=`echo $LANGS | cut -c1,2`
TRG=`echo $LANGS | cut -c3,4`

SUFFIX=$1
shift
GPUS=$1
shift

DATA=./data
MARIAN=../tools/marian-dev/build
MODEL=./models/$LANGS.$SUFFIX

OPTIONS=$@


mkdir -p $MODEL
cp ./validate.sh $MODEL/validate.sh
cp $DATA/$LANGS.vocab.yml $MODEL/vocab.yml


test -e $MODEL/model.npz || $MARIAN/marian \
    --devices $GPUS $OPTIONS \
    --model $MODEL/model.npz --type s2s \
    --train-sets $DATA/$LANGS.train.{src,trg} \
    --vocabs $MODEL/vocab.yml $MODEL/vocab.yml \
    --sqlite $MODEL/corpus.sqlite3 \
    --max-length 80 \
    --mini-batch-fit -w 3000 --mini-batch 100 --maxi-batch 1000 \
    --best-deep \
    --dropout-rnn 0.2 --dropout-src 0.2 --dropout-trg 0.1 \
    --tied-embeddings-all \
    --layer-normalization \
    --exponential-smoothing \
    --learn-rate 0.0001 --lr-decay 0.8 --lr-decay-strategy stalled --lr-decay-start 1 --lr-report \
    --valid-freq 500 --save-freq 2000 --disp-freq 100 \
    --valid-metrics ce-mean-words translation \
    --valid-translation-output $MODEL/dev.out --quiet-translation \
    --valid-sets $DATA/$LANGS.valid.{src,trg} \
    --valid-script-path $MODEL/validate.sh \
    --valid-mini-batch 64 --beam-size 10 --normalize 1.0 \
    --early-stopping 10 --cost-type ce-mean-words \
    --overwrite --keep-best \
    --log $MODEL/train.log --valid-log $MODEL/valid.log


# evaluate
cat $DATA/$LANGS.dev.xml \
    | ../tools/extract-xml.py --source-only \
    | ../tools/tokenize.py \
    | $MARIAN/marian-decoder -c $MODEL/model.npz.best-translation.npz.decoder.yml -d $GPUS -b 10 -n 1.0 --n-best \
      --mini-batch 64 --maxi-batch 10 --maxi-batch-sort src --quiet \
    | tee $MODEL/eval.nbest \
    | ../tools/detokenize.py \
    | ../tools/wrapper_xml.py <( ../tools/detokenize.py < $DATA/$LANGS.dev.src ) --n-best \
    > $MODEL/eval.xml

python ../tools/news_evaluation.py -i $MODEL/eval.xml -t $DATA/$LANGS.dev.xml -o $MODEL/eval.csv \
    | tee $MODEL/eval.txt
