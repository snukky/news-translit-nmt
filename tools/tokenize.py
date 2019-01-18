#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import argparse

WHITESPACE = '<s>'


def main():
    args = parse_args()

    for line in sys.stdin:
        text = line.strip().decode('utf-8').upper()
        toks = args.separator.join(
            [WHITESPACE if c == ' ' else c.encode('utf-8') for c in text])
        sys.stdout.write(toks + '\n')


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--separator", default=' ')
    return parser.parse_args()


if __name__ == "__main__":
    main()
