base:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - bootstrap
        - master
        - container
        - flannel
        - project
        - tools

    # master that has joined the project
    'G@minion-role:master':
        - master
        - container
        - flannel
        - tools
