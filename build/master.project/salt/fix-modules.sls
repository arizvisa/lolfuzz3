Synchronize all modules for the minion:
    module.run:
        - name: saltutil.sync_all
        - refresh: true

Synchronize all modules for the master:
    module.run:
        - name: saltutil.runner
        - m_name: saltutil.sync_all
        - kwargs:
            refresh: true
