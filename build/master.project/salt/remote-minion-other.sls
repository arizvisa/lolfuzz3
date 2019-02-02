include:
    - remote-minion-config

Re-install minion configuration:
    file.managed:
        - template: jinja
        - name: {{ ConfigDir }}/minion
        - source: salt://config/custom.conf
        - defaults:
            master: {{ grains['master'] }}
            hash_type: sha256
            id: {{ grains['id'] }}
            ipc_mode: ipc
            root_dir: {{ Root }}
            saltenv: base
            pillarenv: base
        - mode: 0664

Restart minion with new configuration:
    salt.function:
        - name: minion.restart
        - require:
            - sls: remote-minion-config
            - Re-install minion configuration
