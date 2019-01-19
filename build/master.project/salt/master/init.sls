{% set tools = pillar['master']['tools'] %}
{% set container_service = pillar['master']['service']['container'] %}
{% set salt_container = pillar['master']['service']['salt-master'] %}
{% set MachineID = salt['file.read']('/'.join([pillar['bootstrap']['root'], '/etc/machine-id'])).strip() %}

include:
    - container
    - seed-etcd

Make service directory:
    file.directory:
        - name: /srv
        - mode: 0775
        - makedirs: True

## salt states directories
Make salt-files directory:
    file.directory:
        - name: /srv/salt
        - require:
            - Make service directory
        - use:
            - Make service directory

Make salt-pillar directory:
    file.directory:
        - name: /srv/pillar
        - require:
            - Make service directory
        - use:
            - Make service directory

## salt directories
Make salt-configuration directory:
    file.directory:
        - name: /etc/salt
        - mode: 0770
        - makedirs: True
Make salt-log directory:
    file.directory:
        - name: /var/log/salt
        - mode: 0770
        - makedirs: True
Make salt-cache directory:
    file.directory:
        - name: /var/cache/salt
        - makedirs: True
        - mode: 0775
Make salt-run directory:
    file.directory:
        - name: /var/run/salt
        - use:
            - file: Make salt-cache directory

Install salt-master configuration:
    file.managed:
        - template: jinja
        - source: salt://master/salt-master.conf
        - name: /etc/salt/master
        - defaults:
            etcd_hosts:
                - name: "root_etcd"
                  host: {{ grains['fqdn_ip4'] | last }} # FIXME: this host should come from network.interface xref'd with /etc/network-environment
                  port: 4001

                - name: "minion_etcd"
                  host: {{ grains['fqdn_ip4'] | last }}
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
            - Make salt-configuration directory
        - mode: 0664

Transfer salt-master build rules:
    # FIXME: this file source should be versioned so that container_version can choose which one
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
            - file: Install container-build.service
        - mode: 0664

    event.send:
        - name: build/{{ MachineID }}/salt-master/building
        - data:
            file: "salt-master:{{ salt_container.Version }}.acb"
        - show_changed: true

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
    file.exists:
        - name: "{{ container_service.Path }}/build/salt-master:{{ salt_container.Version }}.acb"
        - require:
            - Transfer salt-master build rules

    cmd.run:
        - name: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -- "{{ pillar['bootstrap']['remote']['host'] }}" sudo -H -E "CONTAINER_DIR={{ container_service.Path }}" -- "{{ container_service.Path }}/build.sh" "{{ container_service.Path }}/build/salt-master:{{ salt_container.Version }}.acb"
        - cwd: {{ container_service.Path }}
        - use_vt: true
        - output_loglevel: debug
        - creates: "{{ container_service.Path }}/image/salt-master:{{ salt_container.Version }}.aci"
        - env:
            - CONTAINER_DIR: {{ container_service.Path }}
        - require:
            - Install openssh-clients in toolbox
            - Install container build script

    event.send:
        - name: build/{{ MachineID }}/salt-master/complete
        - data:
            image: "salt-master:{{ salt_container.Version }}.aci"
        - show_changed: true

Completed salt-master image:
    event.wait:
        - name: build/{{ MachineID }}/salt-master/complete
        - watch:
            - Build salt-master image

    file.managed:
        - name: "{{ container_service.Path }}/image/salt-master:{{ salt_container.Version }}.aci"
        - mode: 0664
        - replace: false

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
            - Completed salt-master image
            - Install salt-master configuration
        - mode: 0664

### symbolic link for service
Enable systemd multi-user.target wants salt-master.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/salt-master.service
        - target: /etc/systemd/system/salt-master.service
        - require:
            - Install salt-master.service
            - sls: seed-etcd
        - makedirs: true

### once we're sure the salt-master.service will run, we can install the salt-minion configuration
Install salt-minion configuration:
    file.managed:
        - template: jinja
        - source: salt://master/salt-minion.conf
        - name: /etc/salt/minion
        - context:
            id: {{ MachineID }}.master.{{ pillar['master']['configuration']['project'] }}
            machine_id: {{ MachineID }}
        - use:
            - Install salt-master configuration
        - require:
            - Enable systemd multi-user.target wants salt-master.service
            - sls: seed-etcd

### Scripts for interacting with the salt-master

Install the toolbox script for bootstrapping the master:
    file.managed:
        - template: jinja
        - source: salt://master/salt-toolbox.command
        - name: {{ tools.prefix }}/bin/salt-toolbox
        - defaults:
            toolbox: /bin/toolbox
            mounts:
                - "/var/run/dbus"
                - "/etc/systemd"
                - "/etc/salt"
                - "/srv"
                - "{{ tools.prefix }}"
        - mode: 0755
        - makedirs: true

Install the script for bootstrapping the master:
    file.managed:
        - template: jinja
        - source: salt://master/salt-bootstrap.command
        - name: {{ tools.prefix }}/bin/salt-bootstrap
        - defaults:
            salt_toolbox: {{ tools.prefix }}/bin/salt-toolbox
        - require:
            - Install the toolbox script for bootstrapping the master
        - mode: 0755
        - makedirs: true

Create the script for interacting with salt:
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

Link the script for calling salt-api:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-api
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Link the script for calling salt-call:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-call
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Link the script for calling salt-cloud:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-cloud
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Link the script for calling salt-cp:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-cp
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Link the script for calling salt-key:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-key
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Link the script for calling salt-run:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-run
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Link the script for calling salt-ssh:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-ssh
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Link the script for calling salt-unity:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-unity
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true
