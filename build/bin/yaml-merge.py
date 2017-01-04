#!/usr/bin/env python
# encoding: utf-8
import sys,platform,os
import itertools,operator,functools
import argparse

def usage():
    res = argparse.ArgumentParser(prog='yaml-merge.py', description='Merge a yaml document into the template document.', add_help=True)
    res.add_argument('template', type=argparse.FileType('r'), help='the yaml file to merge into')
    res.add_argument('source', nargs='*', type=argparse.FileType('r'), help='the source yaml containing what to merge')
    return res

if __name__ == '__main__':
    import hiyapyco

    p = usage()
    args = p.parse_args()
    if not vars(args):
        p.print_usage()
        sys.exit(1)
    
    res = hiyapyco.load( *(args.template.name,) + tuple(map(operator.attrgetter('name'), args.source)), method=hiyapyco.METHOD_MERGE)
    print >>sys.stdout, hiyapyco.dump(res, allow_unicode=False)
