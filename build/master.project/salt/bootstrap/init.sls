#!pyobjects
include('container', 'master', 'seed-etcd')

import os.path
root = pillar('bootstrap:root')

if 'Generate bootstrap-environment from machine-id':
    # read machine-id from pivoted root
    res = os.path.join(root, 'etc/machine-id')
    mid = file(res, 'rt').read().strip()

    # build default template variables from grains
    ip4, ip6 = grains('fqdn_ip4'), grains('fqdn_ip6')
    if not ip4:
        raise ValueError("fqdn_ip4 is unset: {!r}".format(ip4))
    if not ip6:
        raise ValueError("fqdn_ip6 is unset: {!r}".format(ip6))
    defaults = dict(fqdn_ip4=ip4[0], fqdn_ip6=max(ip6, key=len), machine_id=mid)

    # generate bootstrap-environment to pivoted root
    File.managed(
        os.path.join(root, "etc/bootstrap-environment"),
        template='jinja',
        source='salt://bootstrap/bootstrap.env',
        defaults=defaults,
        mode='0664',
        require=[File("Install salt-master.service")]
    )
