## Synchronize module fixes (minion)

include:
    - master-minion

Synchronize all modules for the minion:
    module.run:
        - saltutil.sync_all:
            - refresh: true
        - require:
            - sls: master-minion
