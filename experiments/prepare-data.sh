#!/bin/bash -v

dataset_dev=../datasets/NEWS2018_DATASET_0?/*_dev.xml
dataset_train=../datasets/NEWS2018_DATASET_0?/*_trn.xml


mkdir -p data

for path in $dataset_dev; do
    lang=`basename $path | cut -c12-15`
    file=data/$lang

    echo "Preparing $lang devset"

    test -e $file.dev.xml || cp $path $file.dev.xml
    test -e $file.dev.txt || python3 ../tools/extract-xml.py --one-target < $file.dev.xml > $file.dev.txt
    test -e $file.dev.src.orig || cut -f1 $file.dev.txt > $file.dev.src.orig
    test -e $file.dev.src || cut -f1 $file.dev.txt | python ../tools/tokenize.py > $file.dev.src
done

for path in $dataset_train; do
    lang=`basename $path | cut -c12-15`
    file=data/$lang

    echo "Preparing $lang trainset"

    test -e $file.train.txt || python3 ../tools/split-valid-data.py -n 500 < $path 2> $file.train.txt | sort > $file.valid.txt

    test -e $file.train.src || cut -f1 $file.train.txt | python ../tools/tokenize.py > $file.train.src
    test -e $file.train.trg || cut -f2 $file.train.txt | python ../tools/tokenize.py > $file.train.trg
    test -e $file.valid.src.orig || cut -f1 $file.valid.txt > $file.valid.src.orig
    test -e $file.valid.trg.orig || cut -f2 $file.valid.txt > $file.valid.trg.orig
    test -e $file.valid.xml || python ../tools/wrapper_xml.py -c $file.valid.{src,trg}.orig > $file.valid.xml
    test -e $file.valid.src || python ../tools/tokenize.py < $file.valid.src.orig > $file.valid.src
    test -e $file.valid.trg || python ../tools/tokenize.py < $file.valid.trg.orig > $file.valid.trg
done

for lang in Ch Th Pe He; do
    file1=data/En${lang}
    file2=data/${lang}En

    test -e $file1.dev.xml || continue
    test -e $file2.dev.xml || continue

    echo "Extra data for En${lang}/${lang}En"

    if [[ ! -e $file1.train.filter.src ]]; then
        cat $file1.dev.src $file1.valid.src | sort > $file1.filter.src
        cat $file2.dev.src $file2.valid.src | sort > $file2.filter.src

        paste $file2.train.trg $file2.train.src | python ../tools/filter-testset.py $file1.filter.src > $file1.train.extra.txt 2> $file1.train.src.filtered
        paste $file1.train.trg $file1.train.src | python ../tools/filter-testset.py $file2.filter.src > $file2.train.extra.txt 2> $file2.train.src.filtered

        cut -f1 $file1.train.extra.txt >> $file1.train.src
        cut -f2 $file1.train.extra.txt >> $file1.train.trg
        cut -f1 $file2.train.extra.txt >> $file2.train.src
        cut -f2 $file2.train.extra.txt >> $file2.train.trg
    fi
done

marian=../tools/marian-dev/build

for lang in `ls data/????.train.src | cut -c6-9`; do
    file=data/$lang

    test -e $lang.vocab.yml || cat $file.train.src $file.train.trg | $marian/marian-vocab > data/$lang.vocab.yml
done
