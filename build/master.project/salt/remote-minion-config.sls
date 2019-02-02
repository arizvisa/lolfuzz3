{% set Root = pillar['local']['root'] %}
{% set Config = salt['config.get']('conf_file') %}
{% set ConfigDir = Config.rsplit('/' if Config.startswith('/') else '\\', 1)[0] %}

Create minion configuration directory:
    file.directory:
        - name: "{{ ConfigDir }}/minion.d"

Install minion common configuration:
    file.managed:
        - template: jinja
        - name: "{{ ConfigDir }}/minion.d/common.conf"
        - source: salt://config/common.conf
        - defaults:
            ipv6: false
            transport: zeromq
        - require:
            - Create minion configuration directory

Install minion etcd configuration:
    file.managed:
        - template: jinja
        - name: "{{ ConfigDir }}/minion.d/etcd.conf"
        - source: salt://config/etcd.conf
        - defaults:
            etcd_cache:
                host: {{ opts['master'] | yaml_dquote }}
                port: 2379
                path_prefix: "{{ pillar['configuration']['salt']['namespace'] }}/cache"
                allow_reconnect: true
                allow_redirect: true

            etcd_hosts:
                - name: "root_etcd"
                  host: {{ opts['master'] | yaml_dquote }}
                  port: 2379

                - name: "minion_etcd"
                  host: {{ opts['master'] | yaml_dquote }}
                  port: 2379

            etcd_returner:
                returner: "root_etcd"
                returner_root: "{{ pillar['configuration']['salt']['namespace'] }}/return"
                ttl: {{ 60 * 30 }}

        - require:
            - Create minion configuration directory

Install all required Python modules:
    pip.installed:
        - requirements: salt://config/requirements.txt
        - reload_modules: true
        - require:
            - Install minion common configuration
            - Install minion etcd configuration
