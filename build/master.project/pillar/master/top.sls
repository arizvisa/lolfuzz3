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
