include:
    - remote-minion-config

Re-install minion configuration:
    file.managed:
        - template: jinja
        - name: {{ ConfigDir }}/minion
        - source: salt://config/custom.conf
        - defaults:
            master: {{ grains['master'] }}
            log_level: warning
            hash_type: sha256
            id: {{ grains['id'] }}
            ipc_mode: ipc
            root_dir: {{ Root }}
            saltenv: base
            pillarenv: base
        - mode: 0664

Synchronize all modules for the minion:
    module.run:
        - saltutil.sync_all:
            - refresh: true
        - require:
            - sls: remote-minion-config
            - Re-install minion configuration

Restart minion with new configuration:
    module.run:
        - name: minion.restart
        - onchanges_any:
            - Re-install minion configuration
            - Synchronize all modules for the minion
