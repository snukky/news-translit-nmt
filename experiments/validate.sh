#!/bin/bash

model="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
root=$( realpath $model/../.. )

lang=$( basename $model | cut -c1-4 )

devsrc=$root/data/${lang}.valid.src.orig
devxml=$root/data/${lang}.valid.xml
devout=$1

cat $devout \
    | python $root/../tools/detokenize.py \
    | python $root/../tools/wrapper_xml.py $devsrc \
    2>/dev/null > $model/valid.xml

python $root/../tools/news_evaluation.py -i $model/valid.xml -t $devxml \
    | tee $model/valid.eval \
    | head -n1 \
    | sed -r 's/ACC: *([0-9.]+)*/\1/'
