bootstrap:

    # from packer image
    'G@minion-role:master-bootstrap':
        - bootstrap         # create /etc/bootstrap-environment
        - etcd              # seed etcd with /etc/machine-id
        - container         # create container-directory and build-scripts
        - flannel           # enable the flanneld service
        - stack             # common salt-stack configuration

    # salt-master container and services
        - master
        - reactor

    # salt-minion configuration
        - minion
        - beacon

    # when being deployed/cloned
    'G@minion-role:master': []
#        - reset-id          # remove /etc/machine-id and then restart
#                            # systemd-machine-id-commit.service or call
#                            # systemd-machine-id-setup --root=/media/root --commit
#        - container         # create container-directory and build-scripts
#        - join-master       # register master cluster with etcd
