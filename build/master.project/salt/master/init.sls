{% set container_path = pillar['master']['service']['container']['path'] %}
{% set container_version = pillar['master']['service']['salt']['version'] %}

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
            root_files:
                - name: "base"
                  path: "/srv/salt"

            root_pillars:
                - name: "root"
                  path: "/srv/pillar"

                - name: "bootstrap"
                  path: "/srv/bootstrap/pillar"

            etcd_pillars:
                - name: "root_etcd"
                  host: {{ grains['fqdn_ip4'] | last }} # FIXME: this host should come from network.interface xref'd with /etc/network-environment
                  port: 4001

                - name: "minion_etcd"
                  host: {{ grains['fqdn_ip4'] | last }}
                  port: 4001

            etcd_pillars_ext:
                - name: "root_etcd"
                  path: "/pillar"

                - name: "minion_etcd"
                  path: "/node/%(minion_id)s"

            etcd_returners:
                - name: "root_etcd"
                  path: "/salt/return"
        - require:
            - Make salt-configuration directory
        - mode: 0664

Transfer salt-master build rules:
    # FIXME: this file source should be versioned so that container_version can choose which one
    file.managed:
        - template: jinja
        - source: salt://master/salt-master.acb
        - name: "{{ container_path }}/build/salt-master:{{ container_version }}.acb"
        - defaults:
            version: {{ container_version }}
        - require:
            - Make container-root build directory
            - file: Install container-build.service
        - mode: 0664

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
    cmd.run:
        - name: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -- "{{ pillar['bootstrap']['remote']['host'] }}" sudo -H -E "CONTAINER_DIR={{ container_path }}" -- "{{ container_path }}/build.sh" "{{ container_path }}/build/salt-master:{{ container_version }}.acb"
        - cwd: {{ container_path }}
        - use_vt: true
        - output_loglevel: debug
        - creates: "{{ container_path }}/image/salt-master:{{ container_version }}.aci"
        - env:
            - CONTAINER_DIR: {{ container_path }}
        - require:
            - Install openssh-clients in toolbox
            - Transfer salt-master build rules
            - Install container build script
    file.managed:
        - name: "{{ container_path }}/image/salt-master:{{ container_version }}.aci"
        - mode: 0664
        - replace: true

Install salt-master.service:
    file.managed:
        - template: jinja
        - source: salt://master/salt-master.service
        - name: /etc/systemd/system/salt-master.service
        - defaults:
            version: {{ container_version }}
            container_path: {{ container_path }}
            image_uuid_path: {{ container_path }}/image/salt-master:{{ container_version }}.aci.id
            run_uuid_path: /var/lib/coreos/salt-master.uuid
            services:
                - host: 127.0.0.1
                  port: 4001
        - require:
            - Build salt-master image
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

### Scripts for interacting with the salt-master
Install the toolbox script for managing the master:
    file.managed:
        - template: jinja
        - source: salt://master/salt-toolbox.command
        - name: /opt/bin/salt-toolbox
        - defaults:
            toolbox: /bin/toolbox
            mounts:
                - "/var/run/dbus"
                - "/etc/systemd"
                - "/etc/salt"
                - "/srv"
                - "/opt"
        - mode: 0755
        - makedirs: true

Create the script for executing salt-call:
    file.managed:
        - template: jinja
        - source: salt://master/salt-call.command
        - name: /opt/bin/salt-call
        - defaults:
            salt_toolbox: /opt/bin/salt-toolbox
        - require:
            - Install the toolbox script for managing the master
        - mode: 0755
        - makedirs: true

Create the script for interacting with salt:
    file.managed:
        - template: jinja
        - source: salt://master/salt.command
        - name: /opt/bin/salt
        - defaults:
            rkt: /bin/rkt
            run_uuid_path: /var/lib/coreos/salt-master.uuid
        - require:
            - Install salt-master.service
        - mode: 0755
        - makedirs: true

Create the script for calling salt-run:
    file.symlink:
        - name: /opt/bin/salt-run
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Create the script for calling salt-cp:
    file.symlink:
        - name: /opt/bin/salt-cp
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Create the script for calling salt-key:
    file.symlink:
        - name: /opt/bin/salt-key
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Create the script for calling salt-unity:
    file.symlink:
        - name: /opt/bin/salt-unity
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

Create the script for calling salt-cloud:
    file.symlink:
        - name: /opt/bin/salt-cloud
        - target: salt
        - require:
            - Create the script for interacting with salt
        - makedirs: true

### Enable the service (note: this is dead because we're just updating the symbolic link, not actually starting anything.)
#salt-master.service:
#    service.dead:
#        - enable: true
