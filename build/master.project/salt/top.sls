bootstrap:

    # first (only) master in cluster
    'G@minion-role:master-bootstrap':

        # states used for bootstrap
        - bootstrap         # create /etc/bootstrap-environment
        - etcd              # seed etcd with /etc/machine-id
        - container         # create container-directory and build-scripts
        - flannel           # enable the flanneld service

        # states related to salt-stack
        - stack             # common salt-stack configuration
        - maintenance       # install services that perform regular maintenance
        - sync              # synchronize all the modules

        # salt-master container and services
        - master
        - reactor

        # salt-minion configuration
        - local-minion
        - local-beacon

        # salt-cloud configuration
        - cloud

    # when master is re-deployed or cloned
    'G@minion-role:master':

        # states for joining the cluster
        #- reset-id          # remove /etc/machine-id and then restart
        #- join-master       # register master cluster with etcd
        - local-minion-sync # synchronize the minion

        # states used for services
        - container         # create container-directory and build-scripts

        # states related to salt-stack
        - stack             # common salt-stack configuration
        - maintenance       # install services that perform regular maintenance

        # salt-minion configuration
        - local-minion
        - local-beacon

        # salt-cloud configuration
        - cloud

    # Windows minions that need to be re-provisioned
    'G@os_family:Windows and not G@minion-role:mastere and not G@minion-role:master-bootstrap':
        - remote-minion-config
        - remote-minion-windows

    # Other minions that need to be re-provisioned
    '* and not G@os_family:Windows and not G@minion-role:master and not G@minion-role:master-bootstrap':
        - remote-minion-config
        - remote-minion-other
