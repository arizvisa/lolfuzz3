bootstrap:
    # path to root filesystem while running CoreOS' toolbox
    root: /media/root

    # how the toolbox connects back to the host
    remote:
        host: core@localhost
        key: /home/core/.ssh/id_rsa

    # default cluster size when seeding the etcd master
    etcd:
        size:
            value: 3
