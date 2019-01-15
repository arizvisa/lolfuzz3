base:
    # from packer image
    'G@minion-role:master-bootstrap':
        - container         # create container-directory and build-scripts
        - seed-etcd         # seed etcd with /etc/machine-id
        - master            # create salt-master container and services
        - bootstrap-env     # create /etc/bootstrap-env
#        - flannel           # also for each container

    # when being deployed/cloned
    'G@minion-role:master': []
#        - reset-id          # remove /etc/machine-id and then restart
                            # systemd-machine-id-commit.service or call
                            # systemd-machine-id-setup --root=/media/root --commit
#        - container         # create container-directory and build-scripts
#        - join-master       # register master cluster with etcd
