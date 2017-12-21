#!pyobjects
include('container', 'role-master', 'seed-etcd')

import os.path
root = pillar('bootstrap:root')

if 'Generate bootstrap-environment from machine-id':
    # read machine-id from pivoted root
    res = os.path.join(root, 'etc/machine-id')
    mid = file(res, 'rt').read().strip()

    # build default template variables from grains
    defaults = dict(fqdn_ip4=grains('fqdn_ip4')[0], fqdn_ip6=max(grains('fqdn_ip6'), key=len), machine_id=mid)

    # generate bootstrap-environment to pivoted root
    File.managed(
        os.path.join(root, "etc/bootstrap-environment"),
        mode='0664',
        source='salt://bootstrap-env/bootstrap.env',
        template='jinja',
        defaults=defaults,
        require=[File("Install salt-master.service")]
    )
