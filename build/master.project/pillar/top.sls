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

    'G@minion-role:service':
        - service

    'G@minion-role:client':
        - node
