import json,argparse,os.path

def usage():
    res = argparse.ArgumentParser(prog='fix-template.py', description='Fix a boxcutter-windows template to use packer variables for everything and to only use packer\'s HTTP server for transferring files.', add_help=True)
    res.add_argument('template', type=argparse.FileType('r'), help='the json file to merge into')
    res.add_argument('--indent', type=int, default=2, help='the number of spaces to indent with')
    return res

if __name__ == '__main__':
    import sys,os

    p = usage()
    args = p.parse_args()
    if not vars(args):
        p.print_usage()
        sys.exit(1)

    result = json.load(args.template)

    # fix the builders
    for b in result['builders']:
        b['winrm_username'] = b['ssh_username'] = "{{user `default-username`}}"
        b['winrm_password'] = b['ssh_password'] = "{{user `default-password`}}"
        b['vm_name'] = "{{user `machine-name`}}"
        b['http_directory'] = "{{user `install-input`}}"
        b['output_directory'] = "{{user `install-output`}}"

        # redirect the specified Autounattend.xml to the new one
        i, old_unattend = next((i,path) for i,(path,filename) in enumerate(map(os.path.split, b['floppy_files'])) if filename == 'Autounattend.xml')
        new_unattend = '/'.join(['Autounattend'] + old_unattend.split('/')[1:] + ['Autounattend.xml'])
        b['floppy_files'][i] = new_unattend

        # remove any files that reference 01-install-wget.cmd since it's on the floppy
        i, install_wget = next((i,path) for i,(path,filename) in enumerate(map(os.path.split, b['floppy_files'])) if filename == '01-install-wget.cmd')
        del b['floppy_files'][i]

    # add the environment variables fot the http server
    #for p in result['provisioners']:
    #    env = p.get('environment_vars', [])
    #    env.append('HTTP_IP={{.HTTPIP}}')
    #    env.append('HTTP_PORT={{.HTTPPort}}')

    json.dump(result, sys.stdout, indent=args.indent, ensure_ascii=False)
