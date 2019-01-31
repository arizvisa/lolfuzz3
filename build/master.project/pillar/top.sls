bootstrap:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - bootstrap-local
        - project
        - container
        - salt
        - flannel
        - cloud

    # master that has joined the project
    'G@minion-role:master':
        - local
        - project
        - container
        - salt
