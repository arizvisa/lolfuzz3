bootstrap:

    # bootstrapping a master
    'G@minion-role:master-bootstrap':
        - bootstrap-local
        - flannel
        - cloud
        - toolbox
        - project
        - container
        - salt

    # master that has joined the project
    'G@minion-role:master':
        - local
        - toolbox
        - project
        - container
        - salt
