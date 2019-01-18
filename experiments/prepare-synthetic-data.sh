#!/bin/bash -v


mkdir -p data
mkdir -p synthetic

GPUS=$@
MARIAN=../tools/marian-dev/build


cat data/??En.train.trg data/En??.train.src | sort | uniq > synthetic/En.txt

# collect all En from XxEn and back-translate to Xx = Ch Th He Pe
for revlang in ChEn ThEn PeEn HeEn; do
    lang=`echo $revlang | sed -r 's/(..)(..)/\2\1/'`

    # skip if there is no system for translation
    test -s models/$lang.ens/ensemble.yml || continue

    test -s synthetic/$revlang.trans || cat synthetic/En.txt \
        | bash translate.sh $lang synthetic/$lang.bt $GPUS \
        > synthetic/$revlang.trans

    cat data/$revlang.dev.src > synthetic/$revlang.trans.filter

    paste synthetic/$revlang.trans synthetic/En.txt \
        | python3 ../tools/filter-testset.py -m 35 -q synthetic/$revlang.trans.filter \
        > synthetic/$revlang.train.extra.txt

    cut -f1 synthetic/$revlang.train.extra.txt > synthetic/$revlang.train.src
    cut -f2 synthetic/$revlang.train.extra.txt > synthetic/$revlang.train.trg
    cat data/$revlang.train.src >> synthetic/$revlang.train.src
    cat data/$revlang.train.trg >> synthetic/$revlang.train.trg

    cut -f1 synthetic/$revlang.train.extra.txt > synthetic/$lang.train.trg
    cut -f2 synthetic/$revlang.train.extra.txt > synthetic/$lang.train.src
    cat data/$lang.train.src >> synthetic/$lang.train.src
    cat data/$lang.train.trg >> synthetic/$lang.train.trg

    cp data/$lang.valid.* data/$lang.dev.* synthetic/
done

# oversample HeEn data
if [ -s models/$lang.ens/EnHe.ens/ensemble.yml ]; then
    cat data/HeEn.train.src >> synthetic/HeEn.train.src
    cat data/HeEn.train.trg >> synthetic/HeEn.train.trg

    cat data/EnHe.train.src >> synthetic/EnHe.train.src
    cat data/EnHe.train.trg >> synthetic/EnHe.train.trg
fi

# collect all En from EnXx and forward-translate to Xx
for lang in EnBa EnHi EnKa EnTa EnVi; do
    # skip if there is no system for translation
    test -s models/$lang.ens/ensemble.yml || continue

    test -s synthetic/$lang.trans || cat synthetic/En.txt \
        | bash translate.sh $lang synthetic/$lang.ft $GPUS \
        > synthetic/$lang.trans

    cat data/$lang.dev.src > synthetic/$lang.trans.filter

    paste synthetic/En.txt synthetic/$lang.trans \
        | python3 ../tools/filter-testset.py -m 35 -q synthetic/$lang.trans.filter \
        > synthetic/$lang.train.extra.txt

    cut -f1 synthetic/$lang.train.extra.txt > synthetic/$lang.train.src
    cut -f2 synthetic/$lang.train.extra.txt > synthetic/$lang.train.trg

    for i in `seq 4`; do
        cat data/$lang.train.src >> synthetic/$lang.train.src
        cat data/$lang.train.trg >> synthetic/$lang.train.trg
    done

    cp data/$lang.valid.* data/$lang.dev.* synthetic/
done

# oversample EnVi data
if [ -s models/$lang.ens/EnVi.ens/ensemble.yml ]; then
    for i in `seq 12`; do
        cat data/EnVi.train.src >> synthetic/EnVi.train.src
        cat data/EnVi.train.trg >> synthetic/EnVi.train.trg
    done
fi

# create vocabs
for lang in `ls synthetic/????.train.src | cut -c11-14`; do
    file=synthetic/$lang

    cat $file.train.src $file.train.trg | $MARIAN/marian-vocab > $file.vocab.yml
done
