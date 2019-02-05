master:

    # bootstrapping a master
    'G@role:master-bootstrap':
        - system
        - master
        - master-network
        - project

        # bootstrap configuration
        - flannel
        - cloud
        - toolbox

        # standard service configuration
        - etcd
        - container
        - salt

    # master that has joined the project
    'G@role:master':
        - system
        - master
        - master-network
        - project

        # bootstrap configuration
        - cloud
        - toolbox

        # standard service configuration
        - etcd
        - container
        - salt

bootstrap:
    # any minions that are running Windows
    'G@os_family:Windows':
        - minion-windows

    # any minions that are running Linux
    'not G@os_family:Windows':
        - minion-linux
