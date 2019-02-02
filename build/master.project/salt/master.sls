{% set Root = pillar['local']['root'] %}

### States to bootstrap the salt-master container and install it as a service
include:
    - etcd
    - container
    - stack

## standard salt-master directories
Make salt-master cache directory:
    file.directory:
        - name: {{ Root }}/var/cache/salt/master
        - use:
            - Make salt cache directory
        - require:
            - Make salt cache directory

Make salt-master pki directory:
    file.directory:
        - name: {{ Root }}/etc/salt/pki/master
        - use:
            - Make salt pki directory
        - require:
            - Make salt pki directory

Make salt-master run directory:
    file.directory:
        - name: {{ Root }}/var/run/salt/master
        - use:
            - Make salt run directory
        - require:
            - Make salt run directory

## salt states directories
Make salt-master files directory:
    file.directory:
        - name: /srv/salt
        - use:
            - Make service directory
        - require:
            - Make service directory

Make salt-master pillar directory:
    file.directory:
        - name: /srv/pillar
        - use:
            - Make service directory
        - require:
            - Make service directory

Install an example state topfile:
    file.managed:
        - template: jinja
        - source: salt://stack/default-top-state
        - name: /srv/salt/top.sls
        - defaults:
            environments:
                base:
                    '*': []

            description:
                base: Base environment

            target:
                base:
                    '*': All minions
        - require:
            - Make salt-master files directory
        - mode: 0755
        - makedirs: true

Install an example pillar topfile:
    file.managed:
        - template: jinja
        - source: salt://stack/default-top-state
        - name: /srv/pillar/top.sls
        - defaults:
            environments:
                base:
                    '*': []

            description:
                base: Base environment

            target:
                base:
                    '*': All minions
        - require:
            - Make salt-master pillar directory
        - mode: 0755
        - makedirs: true

Make salt-master configuration directory:
    file.directory:
        - name: {{ Root }}/etc/salt/master.d
        - use:
            - Make salt configuration directory
        - require:
            - Make salt configuration directory

## salt-stack master configuration
Install salt-master configuration:
    file.managed:
        - template: jinja
        - source: salt://config/salt-master.conf
        - name: {{ Root }}/etc/salt/master
        - defaults:
            root_dir: /
            hash_type: sha1
        - require:
            - Make salt configuration directory
        - mode: 0664

Install salt-master base configuration:
    file.managed:
        - template: jinja
        - source: salt://config/master.conf
        - name: {{ Root }}/etc/salt/master.d/base.conf

        - defaults:
            root_files:
                - name: "base"
                  path: "/srv/salt"

                - name: "bootstrap"
                  path: "/srv/bootstrap/salt"

            root_pillars:
                - name: "base"
                  path: "/srv/pillar"

                - name: "bootstrap"
                  path: "/srv/bootstrap/pillar"

            ext_pillars:
                - type: "etcd"
                  name: "root_etcd"
                  path: "/config"

                - type: "etcd"
                  name: "minion_etcd"
                  path: "{{ pillar['configuration']['salt']['namespace'] }}/pillar/%(minion_id)s"

        - require:
            - Make salt-master configuration directory
            - Initialize the nodes pillar namespace
            - Install salt-master etcd configuration
        - mode: 0664

Install salt-master etcd configuration:
    file.managed:
        - template: jinja
        - source: salt://config/etcd.conf
        - name: {{ Root }}/etc/salt/master.d/etcd.conf
        - defaults:
            etcd_cache:
                  host: 127.0.0.1
                  port: 2379
                  path_prefix: "{{ pillar['configuration']['salt']['namespace'] }}/cache"
                  allow_reconnect: true
                  allow_redirect: true

            etcd_hosts:
                - name: "root_etcd"
                  host: 127.0.0.1
                  port: 2379

                - name: "minion_etcd"
                  host: 127.0.0.1
                  port: 2379

            etcd_returner:
                returner: "root_etcd"
                returner_root: "{{ pillar['configuration']['salt']['namespace'] }}/return"
                ttl: {{ 60 * 30 }}

        - require:
            - Make salt-master configuration directory
            - Initialize the cache namespace
            - Initialize the returner namespace
        - mode: 0664

Install salt-master identification configuration:
    file.managed:
        - template: jinja
        - source: salt://config/custom.conf
        - name: {{ Root }}/etc/salt/master.d/id.conf
        - defaults:
            configuration:
                master_id: {{ pillar['local']['machine_id'] }}.{{ pillar['configuration']['project'] }}

        - require:
            - Make salt-master configuration directory
        - mode: 0664

Install salt-master common configuration:
    file.managed:
        - template: jinja
        - source: salt://config/common.conf
        - name: {{ Root }}/etc/salt/master.d/common.conf
        - defaults:
            log_level: info
            ipv6: false
            transport: zeromq
        - require:
            - Make salt-master configuration directory
        - mode: 0664

## services
Install salt-master.service:
    file.managed:
        - template: jinja
        - source: salt://stack/salt.service
        - name: {{ Root }}/etc/systemd/system/salt-master.service

        - context:
            description: Salt-Master
            configuration: /etc/salt/minion

            execute: /usr/bin/salt-master
            kill_mode: process
            after:
                - flanneld.service
            requires:
                - flanneld.service

            network: host
            container_path: {{ pillar['service']['container']['path'] }}
            image_name: lol/salt-stack:{{ pillar['container']['salt-stack']['version'] }}
            image_path: salt-stack:{{ pillar['container']['salt-stack']['version'] }}.aci
            image_uuid_path: salt-stack:{{ pillar['container']['salt-stack']['version'] }}.aci.id
            run_uuid_path: {{ pillar['service']['salt-master']['UUID'] }}

        - use:
            - Generate salt-stack container build rules

        - require:
            - Install salt-master configuration
            - Finished building the salt-stack image
            - Install container load script

        - mode: 0664

# systemctl enable the salt-master.service
Enable systemd multi-user.target wants salt-master.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/salt-master.service
        - target: /etc/systemd/system/salt-master.service
        - require:
            - Install salt-master.service
        - makedirs: true

## scripts for interacting with the salt-master
Install the script for interacting with salt-master:
    file.managed:
        - template: jinja
        - source: salt://scripts/salt.command
        - name: {{ Root }}/opt/bin/salt

        - defaults:
            rkt: /bin/rkt
            unit: salt-master.service
            run_uuid_path: {{ pillar['service']['salt-master']['UUID'] }}

        - require:
            - Finished building the salt-stack image
            - Install salt-master.service

        - mode: 0755
        - makedirs: true

# everything else can just be a symbolic link
Link the script for calling salt-api:
    file.symlink:
        - name: {{ Root }}/opt/bin/salt-api
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-cloud:
    file.symlink:
        - name: {{ Root }}/opt/bin/salt-cloud
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-cp:
    file.symlink:
        - name: {{ Root }}/opt/bin/salt-cp
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-key:
    file.symlink:
        - name: {{ Root }}/opt/bin/salt-key
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-run:
    file.symlink:
        - name: {{ Root }}/opt/bin/salt-run
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-ssh:
    file.symlink:
        - name: {{ Root }}/opt/bin/salt-ssh
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-unity:
    file.symlink:
        - name: {{ Root }}/opt/bin/salt-unity
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

## States for initializing the etcd namespaces
Initialize the salt namespace:
    etcd.directory:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}"
        - profile: root_etcd
        - requires:
            - sls: etcd

# cache
Initialize the cache namespace:
    etcd.directory:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/cache"
        - use:
            - Initialize the salt namespace
        - requires:
            - Initialize the salt namespace

Initialize the minion cache namespace:
    etcd.directory:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/cache/minions"
        - use:
            - Initialize the cache namespace
        - requires:
            - Initialize the cache namespace

# returner
Initialize the returner namespace:
    etcd.directory:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/return"
        - use:
            - Initialize the salt namespace
        - requires:
            - Initialize the salt namespace

Initialize the minion returner namespace:
    etcd.directory:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/return/minions"
        - use:
            - Initialize the returner namespace
        - requires:
            - Initialize the returner namespace

Initialize the jobs returner namespace:
    etcd.directory:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/return/jobs"
        - use:
            - Initialize the returner namespace
        - requires:
            - Initialize the returner namespace

# events
Initialize the events returner namespace:
    etcd.directory:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/return/events"
        - use:
            - Initialize the returner namespace
        - requires:
            - Initialize the returner namespace

# pillar
Initialize the nodes pillar namespace:
    etcd.directory:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/pillar"
        - use:
            - Initialize the salt namespace
        - requires:
            - Initialize the salt namespace
