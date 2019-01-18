#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import argparse
from lxml import etree


def main():
    args = parse_args()
    tree = etree.parse(sys.stdin)

    for name in tree.iterfind('Name'):
        src = name.findtext('SourceName')
        if args.source_only:
            print(src)
            continue

        for tgt in name.iterfind('TargetName'):
            print("{}\t{}".format(src, tgt.text))
            if args.one_target:
                break


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--source-only", action='store_true')
    parser.add_argument("-o", "--one-target", action='store_true')
    return parser.parse_args()


if __name__ == "__main__":
    main()
