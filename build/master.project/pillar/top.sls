bootstrap:

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
        - toolbox

        # standard service configuration
        - etcd
        - container
        - salt

    # any minions that are running Windows
    'not G@minion-role:master-bootstrap and not G@minion-role:master and G@os_family:Windows':
        - minion-windows
        - project

    # any minions that are running Linux
    'not G@minion-role:master-bootstrap and not G@minion-role:master and not G@os_family:Windows':
        - minion-linux
        - project
