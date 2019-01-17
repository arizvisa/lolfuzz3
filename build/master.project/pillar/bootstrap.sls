# configuration for bootstrapping etcd and installation of salt

bootstrap:

    # path to root filesystem while running CoreOS' toolbox
    root: /media/root

    # how the toolbox authenticates back to the host
    remote:
        host: core@localhost
        key: /home/core/.ssh/id_rsa

    # default cluster size when seeding the etcd master
    etcd:
        cluster-size: 3
