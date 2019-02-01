## Synchronize module fixes (minion)

include:
    - local-minion

Synchronize all modules for the minion:
    module.run:
        - saltutil.sync_all:
            - refresh: true
        - require:
            - sls: local-minion

