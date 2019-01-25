# Get the machine-id /etc/machine-id if we're using the bootstrap environment, otherwise use the grain.
{% if grains['minion-role'] == 'master-bootstrap' %}
    {% set Root = pillar['configuration']['root'] %}
    {% set MachineId = salt['file.read']('/'.join([Root, '/etc/machine-id'])).strip() %}
{% else %}
    {% set Root = grains['root'] %}
    {% set MachineId = grains['machine-id'] %}
{% endif %}

# Figure out the external network interface by searching /etc/network-environment
{% set Address = salt['file.grep']('/'.join([Root, '/etc/network-environment']), pattern='^DEFAULT_IPV4=').get('stdout', '').split('=') | last %}
{% set Interface = salt['network.ifacestartswith'](Address) | first %}

### States to bootstrap the salt-master container and install it as a service
include:
    - etcd
    - container
    - stack

## standard salt-master directories
Make salt-master cache directory:
    file.directory:
        - name: /var/cache/salt/master
        - use:
            - Make salt cache directory
        - require:
            - Make salt cache directory

Make salt-master pki directory:
    file.directory:
        - name: /etc/salt/pki/master
        - use:
            - Make salt pki directory
        - require:
            - Make salt pki directory

Make salt-master run directory:
    file.directory:
        - name: /var/run/salt/master
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

Make salt-master configuration directory:
    file.directory:
        - name: /etc/salt/master.d
        - use:
            - Make salt configuration directory
        - require:
            - Make salt configuration directory

## salt-stack master
Install salt-master configuration:
    file.managed:
        - template: jinja
        - source: salt://master/salt-master.conf
        - name: /etc/salt/master

        - defaults:
            id: {{ MachineId }}.master.{{ pillar['configuration']['project'] }}
            log_level: info

            saltenv: base
            pillarenv: base
            rootfs: {{ Root }}

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

            etcd_pillars_ext:
                - name: "root_etcd"
                  path: "/config"

                - name: "minion_etcd"
                  path: "{{ pillar['configuration']['salt']['namespace'] }}/pillar/%(minion_id)s"

            etcd_returner:
                returner: "root_etcd"
                returner_root: "{{ pillar['configuration']['salt']['namespace'] }}/return"
                ttl: {{ 60 * 30 }}

        - context:
            etcd_hosts:
                - name: "root_etcd"
                  host: {{ grains['ip4_interfaces'][Interface] | first }}
                  port: 2379

                - name: "minion_etcd"
                  host: {{ grains['ip4_interfaces'][Interface] | first }}
                  port: 2379

            etcd_cache:
                  host: {{ grains['ip4_interfaces'][Interface] | first }}
                  port: 2379
                  path_prefix: "{{ pillar['configuration']['salt']['namespace'] }}/cache"
                  allow_reconnect: true
                  allow_redirect: true

        - require:
            - Make salt configuration directory
            - Initialize the nodes pillar namespace
        - mode: 0664

Install salt-master.service:
    file.managed:
        - template: jinja
        - source: salt://stack/salt.service
        - name: /etc/systemd/system/salt-master.service

        - context:
            description: Salt-Master
            configuration: /etc/salt/minion

            execute: /usr/bin/salt-master
            kill_mode: process
            after:
                - flanneld.service
            requires:
                - flanneld.service

            network: default
            exposed:
                - name: salt-job
                  number: 4505

                - name: salt-result
                  number: 4506

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
        - name: /etc/systemd/system/multi-user.target.wants/salt-master.service
        - target: /etc/systemd/system/salt-master.service
        - require:
            - Install salt-master.service
        - makedirs: true

## scripts for interacting with the salt-master
Install the script for interacting with salt-master:
    file.managed:
        - template: jinja
        - source: salt://stack/salt.command
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt

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
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-api
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-cloud:
    file.symlink:
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-cloud
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-cp:
    file.symlink:
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-cp
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-key:
    file.symlink:
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-key
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-run:
    file.symlink:
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-run
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-ssh:
    file.symlink:
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-ssh
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-unity:
    file.symlink:
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-unity
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

## States for initializing the etcd namespaces
Initialize the salt namespace:
    etcd.set:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}"
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - sls: etcd

# cache
Initialize the cache namespace:
    etcd.set:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/cache"
        - value: null
        - directory: true
        - use:
            - Initialize the salt namespace
        - requires:
            - Initialize the salt namespace

Initialize the minion cache namespace:
    etcd.set:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/cache/minions"
        - value: null
        - directory: true
        - use:
            - Initialize the cache namespace
        - requires:
            - Initialize the cache namespace

# returner
Initialize the returner namespace:
    etcd.set:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/return"
        - value: null
        - directory: true
        - use:
            - Initialize the salt namespace
        - requires:
            - Initialize the salt namespace

Initialize the minion returner namespace:
    etcd.set:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/return/minions"
        - value: null
        - directory: true
        - use:
            - Initialize the returner namespace
        - requires:
            - Initialize the returner namespace

Initialize the jobs returner namespace:
    etcd.set:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/return/jobs"
        - value: null
        - directory: true
        - use:
            - Initialize the returner namespace
        - requires:
            - Initialize the returner namespace

# events
Initialize the events returner namespace:
    etcd.set:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/return/events"
        - value: null
        - directory: true
        - use:
            - Initialize the returner namespace
        - requires:
            - Initialize the returner namespace

# pillar
Initialize the nodes pillar namespace:
    etcd.set:
        - name: "{{ pillar['configuration']['salt']['namespace'] }}/pillar"
        - value: null
        - directory: true
        - use:
            - Initialize the salt namespace
        - requires:
            - Initialize the salt namespace

