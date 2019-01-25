# configuration of the salt-stack image
container:
    salt-stack:
        version: 2019.2
        python: python2
        pip: pip2

# configuration of the salt-stack services
service:
    salt-master:
        UUID: /var/lib/coreos/salt-master.uuid
        Address: /var/lib/coreos/salt-master.address

    salt-minion:
        UUID: /var/lib/coreos/salt-minion.uuid
        Address: /var/lib/coreos/salt-minion.address
