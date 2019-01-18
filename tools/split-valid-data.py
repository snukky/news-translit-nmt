#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import argparse
import random
from lxml import etree


def main():
    args = parse_args()

    data = []
    tree = etree.parse(sys.stdin)

    for name in tree.iterfind('Name'):
        src = name.findtext('SourceName')
        data.append([src, []])

        for tgt in name.iterfind('TargetName'):
            data[-1][1].append(tgt.text)

    random.seed(args.seed)
    random.shuffle(data)

    for i, srctrgs in enumerate(data):
        src, trgs = srctrgs
        for trg in trgs:
            output = "{}\t{}\n".format(src, trg)
            if i < args.n:
                sys.stdout.write(output)
            else:
                sys.stderr.write(output)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", type=int, default=500)
    parser.add_argument("--seed", type=int, default=123456)
    return parser.parse_args()


if __name__ == "__main__":
    main()
