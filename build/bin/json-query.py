import sys, types
import functools, operator, itertools
import json, objectpath
import argparse

MAXSTRING = 80

def usage():
    res = argparse.ArgumentParser(prog='json-query.py', description='Query some JSON using objectpath syntax.', add_help=True)
    res.add_argument('infile', type=argparse.FileType('r'), help='The file to query.')
    res.add_argument('query', type=str, nargs='*', help='The queries to apply to the file.')
    res.add_argument('-d', '--dump', default=False, action='store_true', help='Whether to dump the results unprocessed.')
    res.add_argument('--max', type=int, default=MAXSTRING, help='The maximum number of characters to output in a string.')
    return res

def clamp(string, width):
    if len(string) <= width:
        return string
    ellipses = '...'
    return string[:width-len(ellipses)] + ellipses

def _recdump(object, indent='', **options):
    recurse = functools.partial(_recdump, **options)

    if isinstance(object, types.DictType):
        return '{' + ', '.join('='.join(map(recurse, kv)) for kv in object.iteritems()) + '}'
    elif isinstance(object, (types.GeneratorType,types.ListType, types.TupleType)):
        return '[' + ', '.join(map(recurse, object)) + ']'
    elif isinstance(object, (types.IntType, types.LongType)):
        return '{:d}'.format(object)
    elif isinstance(object, types.StringTypes):
        if options['dump']:
            return '{:s}'.format(object)

        if any(operator.contains(object, ch) for ch in '\n\t'):
            object = object.replace('\\', r'\\').replace('\n', r'\n').replace('\r', r'\r')
        return '{:s}'.format(clamp(object, options['width']))
    elif isinstance(object, types.NoneType):
        return ''
    return '{!r}'.format(object)

def recdump(object, indent='', **options):
    recurse = functools.partial(_recdump, **options)

    if isinstance(object, types.DictType):
        return '\n'.join('\t'.join(map(recurse, kv)) for kv in object.iteritems())
    elif isinstance(object, (types.GeneratorType,types.ListType, types.TupleType)):
        return '\n'.join(map(recurse, object))
    elif isinstance(object, (types.IntType, types.LongType)):
        return '{:d}'.format(object)
    elif isinstance(object, types.StringTypes):
        return '{:s}'.format(object)
    elif isinstance(object, types.NoneType):
        return ''
    return '{!r}'.format(object)

if __name__ == '__main__':
    p = usage()
    args = p.parse_args()
    if not vars(args):
        p.print_usage()
        sys.exit(1)

    res = json.load(args.infile)
    tree = objectpath.Tree(res)
    output = [tree.execute(q) for q in args.query] if args.query else [res]
    print >>sys.stdout, '\n'.join(recdump(n, dump=args.dump, width=args.max) for n in output)
