## Synchronize module fixes

include:
    - master
    - master-minion

Synchronize all modules for the master:
    salt.runner:
        - name: saltutil.sync_all
        - require:
            - sls: master
            - sls: master-minion

Synchronize all modules for the minion:
    module.run:
        - saltutil.sync_all:
            - refresh: true
        - require:
            - sls: master
            - sls: master-minion
