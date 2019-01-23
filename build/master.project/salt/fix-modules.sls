Synchronize all modules for the minion:
    module.run:
        - saltutil.sync_all:
            - refresh: true
            - saltenv: bootstrap

Synchronize all modules for the master:
    salt.runner:
        - name: saltutil.sync_all
        - saltenv: bootstrap
