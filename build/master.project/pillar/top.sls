master:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - master-bootstrap
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
    'G@minion-role:master':
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
