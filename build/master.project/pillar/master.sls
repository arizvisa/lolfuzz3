# configuration of the salt-master service

master:
    service:
        salt-master:
            Namespace: "/coreos.com/salt"
            Version: 2019.2
            UUID: /var/lib/coreos/salt-master.uuid
            Python: python2
            Pip: pip2
