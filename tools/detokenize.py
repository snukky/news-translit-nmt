#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import argparse

WHITESPACE = '<s>'


def main():
    args = parse_args()

    for line in sys.stdin:
        text = line.strip().replace(args.separator, "").replace(WHITESPACE, " ")
        print(text)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--separator", default=" ")
    return parser.parse_args()


if __name__ == "__main__":
    main()
