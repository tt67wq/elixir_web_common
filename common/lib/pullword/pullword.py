#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# author: wq
# description: ""
import jieba
import sys


def pull_word(content):
    return jieba.cut(content)


def main():
    jieba.setLogLevel(20)
    for seg in pull_word(sys.argv[1]):
        print(seg)


if __name__ == '__main__':
    main()
