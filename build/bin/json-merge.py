#!/usr/bin/env python
# encoding: utf-8
import sys,platform,os
import itertools,operator,functools
import argparse

# FIXME: allow one to specify the schema for jsonmerge

def usage():
    res = argparse.ArgumentParser(prog='json-merge.py', description='Merge a json document into the template document described by the provided path.', add_help=True)
    res.add_argument('template', type=argparse.FileType('r'), help='the json file to merge into')
    res.add_argument('source', nargs='*', type=argparse.FileType('r'), help='the source json containing what to merge')
    res.add_argument('-p', '--path', type=str, default='', help='the path to the branch to merge')
    res.add_argument('--indent', type=int, default=2, help='the number of spaces to indent with')
    return res

def tokenizer(s):
    res, iterable = '', iter(s)
    try:
        while True:
            ch = next(iterable)
            if ch in '[].':
                if res: yield res
                yield ch
                res = ''
                continue
            res += ch
    except StopIteration:
        if res: yield res
    return

def pathify(t):
    n, iterable = '', iter(t)
    try:
        while True:
            n = next(iterable)
            if n == '[':
                n = next(iterable)
                yield int(n, 10)
                n = next(iterable)
                if n != ']': raise ValueError
            elif n == '.': continue
            else: yield n
            continue
    except StopIteration: pass
    except Exception:
        raise ValueError("Parsing error at {!r}".format(n))
    return

def descend(res, path=[]):
    return descend(res[path[0]], path[1:]) if len(path) else res

def store(tree, branch, path=[]):
    if len(path) < 1:
        if all(isinstance(n, dict) for n in (tree, branch)):
            tree.update(branch)
        elif all(isinstance(n, list) for n in (tree, branch)):
            tree[:] = branch[:]
        return tree
    res = descend(tree, path[:-1])
    res[path[-1]].update(branch)
    return tree

if __name__ == '__main__':
    import copy
    import json,jsonmerge

    p = usage()
    args = p.parse_args()
    if not vars(args):
        p.print_usage()
        sys.exit(1)
    
    template = copy.deepcopy(json.load(args.template))
    sources = itertools.imap(json.load, args.source)
    path = list(pathify(tokenizer(args.path)))

    res = descend(template, path)
    try:
        for src in sources:
            res = jsonmerge.merge(res, src)
    except Exception, e:
        print repr(res)
        raise
    result = store(template, res, path)

    if sys.platform == 'win32':
        import msvcrt, os
        msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

    json.dump(result, sys.stdout, indent=args.indent, ensure_ascii=False)
