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
        - master-minion
        - local-beacon

        # salt-cloud configuration
        - cloud

    # when master is re-deployed or cloned
    'G@minion-role:master':

        # states for joining the cluster
        #- reset-id          # remove /etc/machine-id and then restart
        #- join-master       # register master cluster with etcd
        - master-minion-sync # synchronize the minion

        # states used for services
        - container         # create container-directory and build-scripts

        # states related to salt-stack
        - stack             # common salt-stack configuration
        - maintenance       # install services that perform regular maintenance

        # salt-minion configuration
        - master-minion
        - local-beacon

        # salt-cloud configuration
        - cloud
