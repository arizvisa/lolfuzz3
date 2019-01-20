# Get the machine-id from /etc/machine-id
{% set MachineID = salt['file.read']('/'.join([pillar['bootstrap']['root'], '/etc/machine-id'])).strip() %}

# Figure out the external network interface by searching /etc/network-environment
{% set Address = salt['file.grep']('/'.join([pillar['bootstrap']['root'], '/etc/network-environment']), pattern='^DEFAULT_IPV4=').get('stdout', '').split('=') | last %}
{% if Address %}
    {% set Interface = salt['network.ifacestartswith'](Address) | first %}
{% else %}
    {% set Interface = "lo" %}
{% endif %}

# Shortcut variables that point into the pillar configuration
{% set tools = pillar['master']['tools'] %}
{% set container_service = pillar['master']['service']['container'] %}
{% set salt_container = pillar['master']['service']['salt-master'] %}

include:
    - container
    - etcd
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

## saltstack master
Install salt-master configuration:
    file.managed:
        - template: jinja
        - source: salt://master/salt-master.conf
        - name: /etc/salt/master
        - defaults:
            id: {{ MachineID }}.master.{{ pillar['master']['configuration']['project'] }}
            log_level: info

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
                  path: "/node/%(minion_id)s"

            etcd_returners:
                - name: "root_etcd"
                  path: "{{ salt_container.Namespace }}"
        - require:
            - Make salt config directory
        - mode: 0664

Transfer salt-master build rules:
    file.managed:
        - template: jinja
        - source: salt://master/salt-master.acb
        - name: "{{ container_service.Path }}/build/salt-master:{{ salt_container.Version }}.acb"
        - defaults:
            version: {{ salt_container.Version }}
            python: {{ salt_container.Python }}
            pip: {{ salt_container.Pip }}
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
        - target: {{ pillar['bootstrap']['root'] }}{{ pillar['bootstrap']['remote']['key'] }}
        - force: true
        - mode: 0400
        - makedirs : true

Build salt-master image:
    cmd.wait:
        - name: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -- "{{ pillar['bootstrap']['remote']['host'] }}" sudo -H -E "CONTAINER_DIR={{ container_service.Path }}" -- "{{ container_service.Path }}/build.sh" "{{ container_service.Path }}/build/salt-master:{{ salt_container.Version }}.acb"
        - cwd: {{ container_service.Path }}
        - use_vt: true
        - hide_output: true
        - creates: "{{ container_service.Path }}/image/salt-master:{{ salt_container.Version }}.aci"
        - env:
            - CONTAINER_DIR: {{ container_service.Path }}
        - watch:
            - Transfer salt-master build rules
        - require:
            - Install openssh-clients in toolbox
            - Install container build script

Finished building the salt-master image:
    file.managed:
        - name: "{{ container_service.Path }}/image/salt-master:{{ salt_container.Version }}.aci"
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
            version: {{ salt_container.Version }}
            container_path: {{ container_service.Path }}
            image_uuid_path: {{ container_service.Path }}/image/salt-master:{{ salt_container.Version }}.aci.id
            run_uuid_path: {{ salt_container.UUID }}
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
            - sls: etcd
            - Install salt-master.service
            - Finished building the salt-master image
        - makedirs: true

## scripts for interacting with the salt-master
Install the script for interacting with salt-master:
    file.managed:
        - template: jinja
        - source: salt://master/salt.command
        - name: {{ tools.prefix }}/bin/salt
        - defaults:
            rkt: /bin/rkt
            run_uuid_path: {{ salt_container.UUID }}
        - require:
            - Install salt-master.service
        - mode: 0755
        - makedirs: true

# everything else can just be a symbolic link
Link the script for calling salt-api:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-api
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-cloud:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-cloud
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-cp:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-cp
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-key:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-key
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-run:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-run
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-ssh:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-ssh
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

Link the script for calling salt-unity:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-unity
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true

## States for etcd
Create the salt-master pillar:
    etcd.set:
        - name: /node/{{ MachineID }}.master.{{ pillar['master']['configuration']['project'] }}
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - sls: etcd

Register the salt-master namespace:
    etcd.set:
        - name: {{ pillar['master']['service']['salt-master']['Namespace'] }}
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - sls: etcd
