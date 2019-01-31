bootstrap:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - project
        - container
        - salt
        - flannel
        - cloud

    # master that has joined the project
    'G@minion-role:master':
        - project
        - container
        - salt
