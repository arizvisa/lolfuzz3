#!/usr/bin/env python
# encoding: utf-8
import sys,platform,os
import argparse
import functools,operator,itertools

def usage():
    res = argparse.ArgumentParser(prog='yaml-generate.py', description='Generate a yaml document from the arguments', add_help=True)
    res.add_argument('elements', nargs='*', type=str, help='elements used to define document')
    res.add_argument('-d', '--dictionary', action='store_true', help='treat each argument as a key-value pair instead of a single-element of a list')
    res.add_argument('-e', '--environment', action='store_true', help='use the the environment for input')
    res.add_argument('-p', '--path', type=str, default='', help='the path to the branch to write elements to')
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

box = lambda *a: a
unbox = lambda f, *a, **k: lambda *ap, **kp: f(*(a + reduce(operator.add, map(tuple,ap), ())), **dict(k.items() + kp.items()))
identity = lambda n: lambda *a, **k: n
fdiscard = lambda f: lambda *a, **k: f()
fcompose = lambda *f: reduce(lambda f1,f2: lambda *a: f1(f2(*a)), reversed(f))
fcondition = lambda f, t: lambda crit: lambda *a, **k: t(*a, **k) if crit(*a, **k) else f(*a, **k)

if __name__ == '__main__':
    import yaml

    p = usage()
    args = p.parse_args()
    if not vars(args):
        p.print_usage()
        sys.exit(1)

    if args.dictionary:
        value = {}
        f1 = unbox(value.__setitem__)
        f2 = fcompose(operator.methodcaller('split', '='), tuple, unbox(value.__setitem__))
    else:
        value = []
        f1 = fcompose('='.join, value.append)
        f2 = value.append

    if args.environment:
        map(f1, os.environ.iteritems())
    map(f2, args.elements)

    iterable = pathify(tokenizer(args.path))

    state = []
    for n in iterable:
        state.append({n : None} if isinstance(n, basestring) else [])

    res = result = state.pop(0) if len(state) else []
    while len(state):
        n = state.pop(0)
        if isinstance(res, list):
            res.append(n)
            res = res[0]
        elif isinstance(res, dict):
            res[next(res.iterkeys())] = n
            res = res[next(res.iterkeys())]
        else: raise TypeError

    if res:
        res[next(res.iterkeys())] = value
        res = res[next(res.iterkeys())]
    elif isinstance(res, list):
        res[:] = [value]
        res = res[0]

    if sys.platform == 'win32':
        import msvcrt, os
        msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

    print >>sys.stdout, yaml.dump_all(result if isinstance(result, list) else [result], indent=args.indent, allow_unicode=True)
