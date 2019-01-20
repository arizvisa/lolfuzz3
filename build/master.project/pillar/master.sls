# configuration of the salt-master service

master:
    service:
        salt-master:
            Namespace: "/coreos.com/salt"
            UUID: /var/lib/coreos/salt-master.uuid
            Version: 2019.2
            Python: python2
            Pip: pip2

