bootstrap:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - project
        - container
        - salt
        - flannel

    # master that has joined the project
    'G@minion-role:master':
        - master
        - container
        - project
