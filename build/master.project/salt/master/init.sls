{% set Tools = pillar['configuration']['tools'] %}
{% set ContainerService = pillar['service']['container'] %}
{% set SaltContainer = pillar['service']['salt-master'] %}

# Get the machine-id /etc/machine-id if we're using the bootstrap environment, otherwise use the grain.
{% if grains['minion-role'] == 'master-bootstrap' %}
    {% set Root = pillar['configuration']['root'] %}
    {% set MachineId = salt['file.read']('/'.join([Root, '/etc/machine-id'])).strip() %}
{% else %}
    {% set Root = '/media/root' %}
    {% set MachineId = grains['machine-id'] %}
{% endif %}

# Figure out the external network interface by searching /etc/network-environment
{% set Address = salt['file.grep']('/'.join([Root, '/etc/network-environment']), pattern='^DEFAULT_IPV4=').get('stdout', '').split('=') | last %}
{% if Address %}
    {% set Interface = salt['network.ifacestartswith'](Address) | first %}
{% else %}
    {% set Interface = 'lo' %}
{% endif %}

### States to bootstrap the salt-master container and install it as a service
include:
    - stack
    - etcd
    - container

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
            - Make salt config directory
        - require:
            - Make salt config directory

## saltstack master
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

            etcd_hosts:
                - name: "root_etcd"
                  host: {{ grains['ip4_interfaces'][Interface] | first }}
                  port: 4001

                - name: "minion_etcd"
                  host: {{ grains['ip4_interfaces'][Interface] | first }}
                  port: 4001

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
                  path: "{{ SaltContainer.Namespace }}/node/%(minion_id)s"

            etcd_returners:
                - name: "root_etcd"
                  path: "{{ SaltContainer.Namespace }}"
        - require:
            - Make salt config directory
            - Initialize the nodes pillar namespace
        - mode: 0664

Transfer salt-master build rules:
    file.managed:
        - template: jinja
        - source: salt://master/salt-master.acb
        - name: "{{ ContainerService.Path }}/build/salt-master:{{ SaltContainer.Version }}.acb"
        - defaults:
            version: {{ SaltContainer.Version }}
            python: {{ SaltContainer.Python }}
            pip: {{ SaltContainer.Pip }}
            volumes:
                dbus-socket: /var/run/dbus
                salt-etc: /etc/salt
                salt-cache: /var/cache/salt
                salt-logs: /var/log/salt
                salt-run: /var/run/salt
                salt-srv: /srv
                media-root: /media/root
        - require:
            - Make container-root build directory
            - Install container-build.service
        - mode: 0664

# building the salt-master container
Install openssh-clients in toolbox:
    pkg.installed:
        - pkgs:
            - openssh-clients

    file.symlink:
        - name: {{ salt['user.info'](grains['username']).home }}/.ssh/id_rsa
        - target: {{ Root }}{{ pillar['configuration']['remote']['key'] }}
        - force: true
        - mode: 0400
        - makedirs : true

Build salt-master image:
    cmd.run:
        - name: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -- "{{ pillar['configuration']['remote']['host'] }}" sudo -H -E "CONTAINER_DIR={{ ContainerService.Path }}" -- "{{ ContainerService.Path }}/build.sh" "{{ ContainerService.Path }}/build/salt-master:{{ SaltContainer.Version }}.acb"
        - cwd: {{ ContainerService.Path }}
        - hide_output: true
        - creates: "{{ ContainerService.Path }}/image/salt-master:{{ SaltContainer.Version }}.aci"
        - env:
            - CONTAINER_DIR: {{ ContainerService.Path }}
        - require:
            - Transfer salt-master build rules
            - Install openssh-clients in toolbox
            - Install container build script

Finished building the salt-master image:
    file.managed:
        - name: "{{ ContainerService.Path }}/image/salt-master:{{ SaltContainer.Version }}.aci"
        - mode: 0664
        - replace: false
        - watch:
            - Build salt-master image

Install salt-master.service:
    file.managed:
        - template: jinja
        - source: salt://master/salt-master.service
        - name: /etc/systemd/system/salt-master.service
        - defaults:
            version: {{ SaltContainer.Version }}
            container_path: {{ ContainerService.Path }}
            image_uuid_path: {{ ContainerService.Path }}/image/salt-master:{{ SaltContainer.Version }}.aci.id
            run_uuid_path: {{ SaltContainer.UUID }}
            services:
                - host: 127.0.0.1
                  port: 4001
        - require:
            - Install container load script
            - Install salt-master configuration
            - Finished building the salt-master image
        - mode: 0664

# systemctl enable the salt-master.service
Enable systemd multi-user.target wants salt-master.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/salt-master.service
        - target: /etc/systemd/system/salt-master.service
        - require:
            - Install salt-master configuration
            - Finished building the salt-master image
            - Install salt-master.service
        - makedirs: true

## scripts for interacting with the salt-master
Install the script for interacting with salt-master:
    file.managed:
        - template: jinja
        - source: salt://master/salt.command
        - name: {{ Tools.prefix }}/bin/salt
        - defaults:
            rkt: /bin/rkt
            run_uuid_path: {{ SaltContainer.UUID }}
        - require:
            - Finished building the salt-master image
            - Install salt-master.service
        - mode: 0755
        - makedirs: true

# everything else can just be a symbolic link
Link the script for calling salt-api:
    file.symlink:
        - name: {{ Tools.prefix }}/bin/salt-api
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-cloud:
    file.symlink:
        - name: {{ Tools.prefix }}/bin/salt-cloud
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-cp:
    file.symlink:
        - name: {{ Tools.prefix }}/bin/salt-cp
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-key:
    file.symlink:
        - name: {{ Tools.prefix }}/bin/salt-key
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-run:
    file.symlink:
        - name: {{ Tools.prefix }}/bin/salt-run
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-ssh:
    file.symlink:
        - name: {{ Tools.prefix }}/bin/salt-ssh
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-unity:
    file.symlink:
        - name: {{ Tools.prefix }}/bin/salt-unity
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

## States for etcd
Register the salt-master namespace:
    etcd.set:
        - name: "{{ SaltContainer.Namespace }}"
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - sls: etcd

Initialize the nodes pillar namespace:
    etcd.set:
        - name: "{{ SaltContainer.Namespace }}/node"
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - Register the salt-master namespace

Create the pillar for the salt-master:
    etcd.set:
        - name: "{{ SaltContainer.Namespace }}/node/{{ MachineId }}.master.{{ pillar['configuration']['project'] }}"
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - Initialize the nodes pillar namespace
