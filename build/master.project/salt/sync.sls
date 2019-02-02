## Synchronize module fixes

include:
    - master
    - master-minion

Synchronize all modules for the master:
    salt.runner:
        - name: saltutil.sync_all
        - kwarg:
            saltenv: {{ saltenv }}
        - require:
            - sls: master
            - sls: master-minion

Synchronize all modules for the minion:
    module.run:
        - name: saltutil.sync_all
        - refresh: true
        - saltenv: {{ saltenv }}
        - require:
            - sls: master
        - sls: master-minion
