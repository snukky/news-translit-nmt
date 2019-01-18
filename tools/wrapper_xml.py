#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import argparse

TITLE_BEG =\
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" + \
    "\n<TransliterationCorpus" + \
    "\n  TargetLang = \"Xx\"" + \
    "\n  CorpusSize = \"1000\"" + \
    "\n  CorpusFormat = \"UTF8\"" + \
    "\n  SourceLang = \"English\"" + \
    "\n  CorpusID = \"None\"" + \
    "\n  CorpusType = \"\">"
TITLE_END = "</TransliterationCorpus>"

FINAL_TITLE_BEG =\
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>" + \
    "\n<TransliterationTaskResults" + \
    "\n  SourceLang = \"Chinese\"" + \
    "\n  TargetLang = \"English\"" + \
    "\n  GroupID = \"EDI\"" + \
    "\n  RunID = \"1\"" + \
    "\n  RunType = \"Standard\"" + \
    "\n  Comments = \"\">"
FINAL_TITLE_END = "</TransliterationTaskResults>"

MAX_CANDIDATES = 10


def main():
    args = parse_args()

    if args.final:
        args.collapse = True
        args.n_best = True
        print FINAL_TITLE_BEG
    else:
        print TITLE_BEG
    # print >>sys.stderr, TITLE_BEG

    backup = None
    src_last = None
    i = 0
    k = 0
    for src_line in args.source:
        if backup:
            trg_line = backup
            backup = None
        else:
            try:
                trg_line = args.target.next()
            except:
                break


        src_text = src_line.strip()
        if args.collapse and src_text == src_last:
            i -= 1
            k += 1
        else:
            if i != 0:
                print "</Name>"
            src_node = "<SourceName>{}</SourceName>".format(src_text)
            print "<Name id=\"{}\">".format(i + 1)
            print src_node
            k = 0

        if args.n_best:
            j = 1
            while True:
                if not trg_line:
                    break

                idx = int(trg_line.split('|||', 1)[0].strip())
                if idx != i:
                    break

                trg_text = trg_line.split('|||', 3)[1].strip()
                trg_node = "<TargetName ID=\"{}\">{}</TargetName>".format(
                    j, escape_chars(trg_text))
                if trg_text and j <= MAX_CANDIDATES:
                    print trg_node

                j += 1
                trg_line = next(args.target, None)
                backup = trg_line
        else:
            trg_text = trg_line.strip()
            if trg_text:
                trg_node = "<TargetName ID=\"{}\">{}</TargetName>".format(
                    k + 1, escape_chars(trg_text))
                print trg_node

        i += 1
        src_last = src_text

    print "</Name>"
    if args.final:
        print FINAL_TITLE_END
    else:
        print TITLE_END


def escape_chars(text):
   return text.replace('&', '&amp;')


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=argparse.FileType('r'))
    parser.add_argument("target", nargs='?', type=argparse.FileType('r'),
                        default=sys.stdin)
    parser.add_argument("-n", "--n-best", action='store_true')
    parser.add_argument("-c", "--collapse", action='store_true')
    parser.add_argument("-f", "--final", action='store_true')
    return parser.parse_args()


if __name__ == "__main__":
    main()
