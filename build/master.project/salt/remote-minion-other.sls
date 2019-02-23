{% set Root = pillar["local"]["root"] %}
{% set Config = salt["config.get"]("conf_file") %}
{% set ConfigDir = Config.rsplit("/" if Config.startswith("/") else "\\", 1)[0] %}

include:
    - remote-minion-common

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

        - require:
            - sls: remote-minion-common
        - mode: 0664

Restart minion with new configuration:
    module.run:
        - name: minion.restart
        - require:
            - sls: remote-minion-common
            - Re-install minion configuration
