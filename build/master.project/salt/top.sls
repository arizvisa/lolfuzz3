bootstrap:

# first (only) master in cluster
    'G@minion-role:master-bootstrap':
        - bootstrap         # create /etc/bootstrap-environment
        - etcd              # seed etcd with /etc/machine-id
        - container         # create container-directory and build-scripts
        - flannel           # enable the flanneld service
        - stack             # common salt-stack configuration
        - maintenance       # install services that perform regular maintenance

    # salt-master container and services
        - master
        - reactor

    # salt-minion configuration
        - local-minion
        - local-beacon

    # salt-cloud configuration
        - cloud

# when master is re-deployed or cloned
    'G@minion-role:master': []
#        - reset-id          # remove /etc/machine-id and then restart
#                            # systemd-machine-id-commit.service or call
#                            # systemd-machine-id-setup --root=/media/root --commit
#        - container         # create container-directory and build-scripts
#        - join-master       # register master cluster with etcd
