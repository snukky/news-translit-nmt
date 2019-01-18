#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import argparse


def main():
    args = parse_args()

    lastNum = 0
    bestScore = -9999
    numScores = []

    for line in sys.stdin:
        line = line.rstrip("\n")
        fields = line.split(" ||| ")
        scores = [float(s) for s in fields[2].split(" ") if s[-1] != "="]
        length = float(len(fields[1].split(" ")) + 1)

        score = sum(scores) / length ** args.normalize

        num = int(fields[0])
        if num > lastNum:
            numScores.sort(key=lambda tup: tup[0])
            if args.n_best:
                for _, newLine, _ in reversed(numScores):
                    print newLine
            else:
                print numScores[-1][2]

            lastNum = num
            numScores = []

        newLine = " ||| ".join(fields[:-1]) + " ||| " + str(score)
        text = fields[1]
        numScores.append((score, newLine, text))

    numScores.sort(key=lambda tup: tup[0])
    if args.n_best:
        for _, newLine, _ in reversed(numScores):
            print newLine
    else:
        print numScores[-1][2]


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-b", "--n-best", action='store_true')
    parser.add_argument("-n", "--normalize", type=float, default=1.0)
    return parser.parse_args()


if __name__ == "__main__":
    main()
