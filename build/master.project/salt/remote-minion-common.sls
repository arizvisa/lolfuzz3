{% set Root = pillar["local"]["root"] %}
{% set Config = salt["config.get"]("conf_file") %}
{% set ConfigDir = Config.rsplit("/" if Config.startswith("/") else "\\", 1)[0] %}

Upgrade required package -- pip:
    pip.installed:
        - name: pip
        - upgrade: true

Install all required Python modules:
    pip.installed:
        - requirements: salt://config/requirements.txt
        - reload_modules: true
        - ignore_installed: true
        - require:
            - Upgrade required package -- pip

Create minion configuration directory:
    file.directory:
        - name: '{{ ConfigDir }}/minion.d'
        - require:
            - Install all required Python modules

Install minion common configuration:
    file.managed:
        - template: jinja
        - name: '{{ ConfigDir }}/minion.d/common.conf'
        - source: salt://config/common.conf
        - defaults:
            ipv6: false
            transport: zeromq
        - require:
            - Create minion configuration directory

Install minion etcd configuration:
    file.managed:
        - template: jinja
        - name: '{{ ConfigDir }}/minion.d/etcd.conf'
        - source: salt://config/etcd.conf
        - defaults:
            etcd_cache:
                host: {{ opts["master"] | yaml_dquote }}
                port: 2379
                path_prefix: '{{ pillar["configuration"]["salt"] }}/cache'
                allow_reconnect: true
                allow_redirect: true

            etcd_hosts:
                - name: root_etcd
                  host: {{ opts["master"] | yaml_dquote }}
                  port: 2379

                - name: minion_etcd
                  host: {{ opts["master"] | yaml_dquote }}
                  port: 2379

            etcd_returner:
                returner: root_etcd
                returner_root: '{{ pillar["configuration"]["salt"] }}/return'

        - require:
            - Create minion configuration directory

Synchronize all modules for the minion:
    module.run:
        - func: saltutil.sync_all
        - kwargs:
            saltenv: bootstrap
        - require:
            - Install all required Python modules

{% if grains["saltversioninfo"][0] | int < 3000 -%}
Deploy the salt.utils.templates module directly into the remote-minion's site-packages:
    file.managed:
        - name: {{ grains["saltpath"] }}/utils/templates.py
        - source: salt://_utils/templates.py
        - require:
            - Install all required Python modules

Deploy the salt.utils.path module directly into the remote-minion's site-packages:
    file.managed:
        - name: {{ grains["saltpath"] }}/utils/path.py
        - source: salt://_utils/path.py
        - require:
            - Install all required Python modules
{% endif -%}
