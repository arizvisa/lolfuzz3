# configuration of the salt-stack image
container:
    salt-stack:
        Version: 2019.2
        Python: python2
        Pip: pip2

# configuration of the salt-stack services
service:
    salt-master:
        UUID: /var/lib/coreos/salt-master.uuid

    salt-minion:
        UUID: /var/lib/coreos/salt-minion.uuid
