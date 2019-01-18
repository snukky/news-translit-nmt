#!/bin/bash

printf '%-40s\tACC     Fscore  MRR     MAPref\n' " "
for file in `ls -d models*/*/eval.txt`; do
    model=`dirname $file`
    printf '%-40s' "$model"
    echo -en "\t"
    echo -e `cat $file 2>/dev/null | cut -c15-20 | tr '\n' ' ' | sed 's/ /\\\t/g'`
done
