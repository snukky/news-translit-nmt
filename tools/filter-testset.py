#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import argparse


def main():
    args = parse_args()
    data = set([l.rstrip() for l in args.testfile.readlines()])

    for line in sys.stdin:
        src, _ = line.strip().split("\t", 1)

        if args.maxlen and len(src.split()) > args.maxlen:
            if not args.quiet:
                sys.stdout.write(line)
            continue

        if src not in data:
            sys.stdout.write(line)
        elif not args.quiet:
            sys.stdout.write(line)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("testfile", type=argparse.FileType('r'))
    parser.add_argument("-m", "--maxlen", type=int)
    parser.add_argument("-q", "--quiet", action='store_true')
    return parser.parse_args()


if __name__ == "__main__":
    main()
