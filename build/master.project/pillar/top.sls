bootstrap:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - bootstrap-local
        - local-network
        - flannel
        - cloud
        - toolbox
        - project
        - container
        - salt

    # master that has joined the project
    'G@minion-role:master':
        - local
        - local-network
        - toolbox
        - project
        - container
        - salt
