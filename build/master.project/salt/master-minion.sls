{% set Root = pillar["local"]["root"] %}

### States to build the salt-minion configuration for managing the salt-master
include:
    - stack

Make salt-minion cache directory:
    file.directory:
        - name: '{{ Root }}/var/cache/salt/minion'
        - use:
            - Make salt cache directory
        - require:
            - Make salt cache directory

Make salt-minion pki directory:
    file.directory:
        - name: '{{ Root }}/etc/salt/pki/minion'
        - use:
            - Make salt pki directory
        - require:
            - Make salt pki directory

Make salt-minion run directory:
    file.directory:
        - name: /var/run/salt/minion
        - use:
            - Make salt run directory
        - require:
            - Make salt run directory

Make salt-minion configuration directory:
    file.directory:
        - name: '{{ Root }}/etc/salt/minion.d'
        - use:
            - Make salt configuration directory
        - require:
            - Make salt configuration directory

## salt-minion configuration
Install salt-minion configuration:
    file.managed:
        - template: jinja
        - source: salt://config/salt-minion.conf
        - name: '{{ Root }}/etc/salt/minion'
        - defaults:
            root_dir: /
            hash_type: sha256
            log_level: warning
        - require:
            - Make salt configuration directory
        - mode: 0664

Install salt-minion masterless configuration:
    file.managed:
        - template: jinja
        - source: salt://config/master.conf
        - name: '{{ Root }}/etc/salt/minion.d/masterless.conf'
        - defaults:
            root_files:
                - name: base
                  path: /srv/salt

                - name: master
                  path: /srv/bootstrap/salt

                - name: bootstrap
                  path: /srv/bootstrap/salt

            root_pillars:
                - name: base
                  path: /srv/pillar

                - name: master
                  path: /srv/bootstrap/pillar

                - name: bootstrap
                  path: /srv/bootstrap/pillar

            ext_pillars:
                - type: etcd
                  name: root_etcd
                  path: /config

                - type: etcd
                  name: minion_etcd
                  path: '{{ pillar["configuration"]["salt"] }}/pillar/%(minion_id)s'

        - require:
            - Make salt-minion configuration directory
            - Install salt-minion configuration
        - mode: 0664

Install salt-minion etcd configuration:
    file.managed:
        - template: jinja
        - source: salt://config/etcd.conf
        - name: '{{ Root }}/etc/salt/minion.d/etcd.conf'
        - defaults:
            etcd_cache:
                  host: 127.0.0.1
                  port: 2379
                  path_prefix: '{{ pillar["configuration"]["salt"] }}/cache'
                  allow_reconnect: true
                  allow_redirect: true

            etcd_hosts:
                - name: root_etcd
                  host: 127.0.0.1
                  port: 2379

                - name: minion_etcd
                  host: 127.0.0.1
                  port: 2379

            etcd_returner:
                returner: root_etcd
                returner_root: '{{ pillar["configuration"]["salt"] }}/return'

        - require:
            - Make salt-minion configuration directory
        - mode: 0664

{% set id = salt["file.grep"](Root + "/etc/os-release", "^ID=")["stdout"].split("=")[-1] %}
{% set fullname = salt["file.grep"](Root + "/etc/lsb-release", "^DISTRIB_ID=")["stdout"].split("=")[-1] %}
{% set release = salt["file.grep"](Root + "/etc/lsb-release", "^DISTRIB_RELEASE=")["stdout"].split("=")[-1] %}
{% set codename = salt["file.grep"](Root + "/etc/lsb-release", "^DISTRIB_CODENAME=")["stdout"].split("=")[-1] %}
{% set version = salt["file.grep"](Root + "/etc/os-release", "^VERSION=")["stdout"].split("=")[-1] %}
{% set build = salt["file.grep"](Root + "/etc/os-release", "^BUILD_ID=")["stdout"].split("=")[-1] %}

Install salt-minion identification configuration:
    file.managed:
        - template: jinja
        - source: salt://config/custom.conf
        - name: '{{ Root }}/etc/salt/minion.d/id.conf'
        - defaults:
            configuration:
                id: '{{ pillar["local"]["machine_id"] }}'
                master: localhost

                saltenv: master
                pillarenv: master

                grains:
                    role: master
                    machine-id: {{ pillar["local"]["machine_id"] | yaml_dquote }}

                    os: {{ id | yaml_dquote }}
                    os_family: core
                    oscodename: {{ codename | yaml_dquote }}
                    osfinger: '{{ id }}-{{ version }}'
                    osfullname: {{ fullname | yaml_dquote }}
                    osmajorrelease: {{ release | yaml_dquote }}
                    osrelease: {{ release | yaml_dquote }}
                    osbuild: {{ build | yaml_dquote }}

        - require:
            - Make salt-minion configuration directory
        - mode: 0664

Install salt-minion common configuration:
    file.managed:
        - template: jinja
        - source: salt://config/common.conf
        - name: '{{ Root }}/etc/salt/minion.d/common.conf'
        - defaults:
            ipv6: false
            transport: zeromq
        - require:
            - Make salt-minion configuration directory
        - mode: 0664

## services
Install salt-minion.service:
    file.managed:
        - template: jinja
        - source: salt://stack/salt.service
        - name: '{{ Root }}/etc/systemd/system/salt-minion.service'

        - context:
            description: Salt-Minion
            configuration: /etc/salt/minion

            execute: /usr/bin/salt-minion
            kill_mode: control-group
            after:
                - salt-master.service
            requires:
                - salt-master.service

            network: host
            exposed: []

            container_path: {{ pillar["service"]["container"]["paths"]["base"] | yaml_dquote }}
            container_image_path: {{ pillar["service"]["container"]["paths"]["image"] | yaml_dquote }}
            image_name: 'lol/salt-stack:{{ pillar["container"]["salt-stack"]["version"] }}'
            image_path: 'salt-stack:{{ pillar["container"]["salt-stack"]["version"] }}.aci'
            image_uuid_path: 'salt-stack:{{ pillar["container"]["salt-stack"]["version"] }}.id'
            run_uuid_path: {{ pillar["service"]["salt-minion"]["UUID"] | yaml_dquote }}

        - use:
            - Generate salt-stack container build rules
        - require:
            - Install salt-minion configuration
            - Install salt-minion common configuration
            - Finished building the salt-stack image
        - mode: 0644

# systemctl enable the salt-minion.service
Enable systemd multi-user.target wants salt-minion.service:
    file.symlink:
        - name: '{{ Root }}/etc/systemd/system/multi-user.target.wants/salt-minion.service'
        - target: /etc/systemd/system/salt-minion.service
        - require:
            - Install salt-minion.service
        - makedirs: true

## scripts for interacting with the salt-minion
Install the script for starting the bootstrap environment:
    file.managed:
        - template: jinja
        - source: salt://scripts/salt-bootstrap.command
        - name: '{{ Root }}/opt/sbin/salt-bootstrap'

        - context:
            salt_toolbox: /opt/sbin/salt-toolbox

        - require:
            - Install the salt-toolbox wrapper

        - mode: 0755
        - makedirs: true

Install the script for calling salt-call:
    file.managed:
        - template: jinja
        - source: salt://scripts/salt.command
        - name: '{{ Root }}/opt/bin/salt-call'

        - defaults:
            rkt: /bin/rkt
            unit: salt-minion.service
            run_uuid_path: {{ pillar["service"]["salt-minion"]["UUID"] | yaml_dquote }}

        - require:
            - Finished building the salt-stack image
            - Install salt-minion.service

        - mode: 0755
        - makedirs: true

Check etcd is reachable by the minion:
    firewall.check:
        - name: {{ salt["config.get"]("root_etcd")["etcd.host"] | yaml_dquote }}
        - port: {{ salt["config.get"]("root_etcd")["etcd.port"] | yaml_encode }}

Register the pillar for the salt-minion:
    etcd.directory:
        - name: '{{ pillar["configuration"]["salt"] }}/pillar/{{ pillar["local"]["machine_id"] }}'
        - profile: root_etcd
        - requires:
            - Check etcd is reachable by the minion
