## Synchronize module fixes (minion)

include:
    - master-minion

Synchronize all modules for the minion:
    module.run:
        - name: saltutil.sync_all
        - refresh: true
        - saltenv: {{ saltenv }}
        - require:
            - sls: master-minion

