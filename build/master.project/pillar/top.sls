bootstrap:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - project
        - master
        - container
        - flannel

    # master that has joined the project
    'G@minion-role:master':
        - master
        - container
        - project
