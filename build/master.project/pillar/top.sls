base:
    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - bootstrap
        - master
        - flanneld
        - container

    # master that has joined the project
    'G@minion-role:master':
        - master
        - flanneld
        - container
