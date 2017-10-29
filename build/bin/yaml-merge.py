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
    import yamlreader
    from yamlreader.yamlreader import yaml_load, safe_dump

    p = usage()
    args = p.parse_args()
    if not vars(args):
        p.print_usage()
        sys.exit(1)
    
    files = (args.template.name,) + tuple(map(operator.attrgetter('name'), args.source))
    res = yaml_load(files, defaultdata={})

    if sys.platform == 'win32':
        import msvcrt, os
        msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)

    print >>sys.stdout, safe_dump(res, allow_unicode=True)
