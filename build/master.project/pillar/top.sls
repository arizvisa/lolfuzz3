base:
    'G@minion-role:master-bootstrap':
        - bootstrap
        - master
        - flanneld
        - container

    'G@minion-role:master':
        - master
        - flanneld
        - container
