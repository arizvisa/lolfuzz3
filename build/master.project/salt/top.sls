bootstrap:

    # from packer image
    'G@minion-role:master-bootstrap':
        - bootstrap         # create /etc/bootstrap-environment
        - etcd              # seed etcd with /etc/machine-id
        - container         # create container-directory and build-scripts
        - stack             # common salt-stack configuration
        - master            # create salt-master container and services
        - minion            # create the salt-minion for managing the master
        - flannel           # enable the flanneld service

    # when being deployed/cloned
    'G@minion-role:master': []
#        - reset-id          # remove /etc/machine-id and then restart
#                            # systemd-machine-id-commit.service or call
#                            # systemd-machine-id-setup --root=/media/root --commit
#        - container         # create container-directory and build-scripts
#        - join-master       # register master cluster with etcd
