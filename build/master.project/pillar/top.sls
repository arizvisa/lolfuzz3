bootstrap:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - local-bootstrap
        - local-network

        - flannel
        - cloud
        - toolbox

        - etcd
        - container
        - salt

        - project

    # master that has joined the project
    'G@minion-role:master':
        - local
        - local-network
        - toolbox
        - project
        - etcd
        - container
        - salt

    # any minions that are running Windows
    'G@os_family:Windows':
        - local-windows
        - project
