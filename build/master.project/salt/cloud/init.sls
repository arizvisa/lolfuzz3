{% set Root = pillar['local']['root'] %}
{% set Interface = pillar['local']['interface'] %}

include:
    - stack

### salt-cloud configuration
Install salt-cloud configuration:
    file.managed:
        - template: jinja
        - source: salt://cloud/cloud.conf
        - name: {{ Root }}/etc/salt/cloud
        - defaults:
            log_level: info
            pool_size: 10
            minion:
                master: {{ grains['ip4_interfaces'][Interface] | first }}

                # FIXME: this configuration should be barely enough to connect to the master
                #        and then the full config should be applied by a state
                ipv6: false
                transport: zeromq

                use_superseded:
                  - module.run

                mine_return_job: true

                root_etcd:
                    etcd.host: {{ grains['ip4_interfaces'][Interface] | first }}
                    etcd.port: 2379
                minion_etcd:
                    etcd.host: {{ grains['ip4_interfaces'][Interface] | first }}
                    etcd.port: 2379

                etcd.host: {{ grains['ip4_interfaces'][Interface] | first }}
                etcd.port: 2379
                etcd.path_prefix: "{{ pillar['configuration']['salt']['namespace'] }}/cache"
                etcd.allow_reconnect: true
                etcd.allow_redirect: true

                etcd.returner: root_etcd
                etcd.returner_root: "{{ pillar['configuration']['salt']['namespace'] }}/return"
                etcd.ttl: {{ 60 * 30 }}

        - require:
            - Make salt configuration directory
        - mode: 0664

### Service directories
Make salt-cloud configuration directory:
    file.directory:
        - name: /srv/cloud
        - mode: 1775
        - require:
            - Make service directory
        - use:
            - Make service directory

Make salt-cloud providers directory:
    file.directory:
        - name: /srv/cloud/providers
        - require:
            - Make salt-cloud configuration directory
        - use:
            - Make salt-cloud configuration directory

Make salt-cloud profiles directory:
    file.directory:
        - name: /srv/cloud/profiles
        - require:
            - Make salt-cloud configuration directory
        - use:
            - Make salt-cloud configuration directory

## Installation of service directories
Install salt-cloud providers directory:
    file.symlink:
        - name: {{ Root }}/etc/salt/cloud.providers.d
        - target: /srv/cloud/providers
        - require:
            - Make salt configuration directory
            - Make salt-cloud providers directory

Install salt-cloud profiles directory:
    file.symlink:
        - name: {{ Root }}/etc/salt/cloud.profiles.d
        - target: /srv/cloud/profiles
        - require:
            - Make salt configuration directory
            - Make salt-cloud profiles directory

### Example configurations
Download Salt-Minion windows installer:
    file.managed:
        - source: {{ pillar['cloud']['windows']['url'] }}
        - name: /srv/cloud/{{ pillar['cloud']['windows']['installer'] }}
        - source_hash: {{ pillar['cloud']['windows']['checksum'] }}
        - skip_verify: true
        - mode: 0664

Install an example cloud provider:
    file.managed:
        - template: jinja
        - source: salt://cloud/providers.conf
        - name: /srv/cloud/providers/default.conf
        - defaults:
              providers:
                  saltify-linux:
                      driver: saltify
                      deploy: true
                      force_minion_config: true
                      remove_config_on_destroy: true
                      shutdown_on_destroy: true

                  saltify-windows:
                      driver: saltify
                      deploy: true
                      force_minion_config: true
                      remove_config_on_destroy: true
                      shutdown_on_destroy: true

                      use_winrm: true
                      winrm_use_ssl: false
                      winrm_verify_ssl: false
                      winrm_port: 5985
                      win_installer: /srv/cloud/{{ pillar['cloud']['windows']['installer'] }}

        - require:
            - Make salt-cloud providers directory
            - Download Salt-Minion windows installer
        - mode: 0664

Install an example cloud profile:
    file.managed:
        - template: jinja
        - source: salt://cloud/profiles.conf
        - name: /srv/cloud/profiles/default.conf
        - defaults:
              profiles:
                  {}
        - require:
            - Make salt-cloud profiles directory
        - mode: 0664

