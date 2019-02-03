{% set Root = pillar["local"]["root"] %}
{% set Config = salt["config.get"]("conf_file") %}
{% set ConfigDir = Config.rsplit("/" if Config.startswith("/") else "\\", 1)[0] %}

include:
    - remote-minion-config

Re-install minion configuration:
    file.managed:
        - template: jinja
        - name: '{{ ConfigDir }}/minion'
        - source: salt://config/custom.conf
        - defaults:
            configuration:
                master: {{ grains["master"] | yaml_dquote }}
                log_level: warning
                hash_type: sha256
                id: {{ grains["id"] | yaml_dquote }}
                ipc_mode: ipc
                root_dir: {{ Root | yaml_dquote }}
                startup_states: highstate
                saltenv: base
                pillarenv: base
        - mode: 0664

Synchronize all modules for the minion:
    module.run:
        - name: saltutil.sync_all:
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
