#!pyobjects
import os.path
import salt
from salt.serializers import json

## extract host and port number from config('root_etcd:etcd.host') and config('root_etcd:etcd.port') configuration.
Server = dict(
    host=config('root_etcd:etcd.host'),
    port=config('root_etcd:etcd.port')
)

with Firewall.check(Server['host'], port=Server['port'], proto='tcp'):

    ## register machine-id with the discovery protocol
    res = os.path.join(pillar('bootstrap:root'), 'etc/machine-id')
    mid = file(res, 'rt').read().strip()
    uri = "http://{:s}:{:d}/v2/keys/discovery/{:s}/_config/{:s}".format(Server['host'], Server['port'], mid, '{:s}')

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

    ## init the default namespace for nodes
    if hasattr(Etcd, 'directory'):
        Etcd.directory("/node", profile='root_etcd')

    ## create a namespace for project-specific configuration
    if hasattr(Etcd, 'directory'):
        Etcd.directory('/config', profile='root_etcd')

    # populate it
    Config = pillar('master:configuration')
    for var in Config:
        Etcd.set("/config/{:s}".format(var), value=json.serialize(Config[var]), profile="root_etcd")

    ## register the salt-master namespace
    res = pillar('master:service:salt-master')
    if hasattr(Etcd, 'directory'):
        Etcd.directory(res['Namespace'], profile='root_etcd')

    ## register the network config (flannel)
    res = pillar('master:service:flannel')
    if hasattr(Etcd, 'directory'):
        Etcd.directory(res['Namespace'], profile='root_etcd')

    # write the settings
    Etcd.set("{:s}/config".format(res['Namespace']), value=json.serialize(res))
