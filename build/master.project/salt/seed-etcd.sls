#!pyobjects
import os.path
import salt
from salt.serializers import json

root_etcd = dict(
    host=config('root_etcd:etcd.host'),
    port=config('root_etcd:etcd.port')
)

# FIXME: extract host and port number from config('root_etcd:etcd.host') and config('root_etcd:etcd.port') configuration.
with Firewall.check(root_etcd['host'], port=root_etcd['port'], proto='tcp'):

    # init the etcd root namespace
    if hasattr(Etcd, 'directory'):
        Etcd.directory("/node", profile='root_etcd')
        Etcd.directory("/project", profile='root_etcd')
        Etcd.directory("/project/target", profile='root_etcd')
        Etcd.directory("/project/pod", profile='root_etcd')
        Etcd.directory("/project/service", profile='root_etcd')
        Etcd.directory("/project/node", profile='root_etcd')
        Etcd.directory("/project/roles", profile='root_etcd')
        Etcd.directory("/project/role/master", profile='root_etcd')
        Etcd.directory("/project/role/service", profile='root_etcd')
        Etcd.directory("/project/role/node", profile='root_etcd')

    # register with the discovery protocol
    res = os.path.join(pillar('bootstrap:root'), 'etc/machine-id')
    mid = file(res, 'rt').read().strip()
    uri = "http://{:s}:{:d}/v2/keys/discovery/{:s}/_config/{:s}".format(root_etcd['host'], root_etcd['port'], mid, '{:s}')

    for item, dictionary in pillar('bootstrap:etcd').iteritems():
        res = uri.format(item)
        response = salt.utils.http.query(res, method='GET').get('status', 200)
        if response != 200:
            Http.query(res,
                method='PUT',
                data=';'.join("{:s}={:s}".format(k, str(v)) for k, v in dictionary.iteritems()),
                status=201
            )
        continue

    # register the network config (flanneld)
    res = pillar('master:service:flanneld')
    if hasattr(Etcd, 'directory'):
        Etcd.directory("/coreos.com/network", profile='root_etcd')
    Etcd.set("/coreos.com/network/config", value=json.serialize(res))
