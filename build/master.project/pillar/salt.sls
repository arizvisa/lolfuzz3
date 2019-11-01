# configuration of the salt-stack image
container:
    salt-stack:
        bootstrap: https://bootstrap.saltstack.com

        version: 2019.2.0
        python: python3
        pip: pip3

# configuration of the salt-stack services
service:
    salt-master:
        UUID: /var/lib/coreos/salt-master.uuid

    salt-minion:
        UUID: /var/lib/coreos/salt-minion.uuid
