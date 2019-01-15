{% set container_path = pillar['master']['service']['container']['path'] %}
{% set container_version = pillar['master']['service']['salt']['version'] %}

include:
    - container
    - seed-etcd

Make salt-configuration directory:
    file.directory:
        - name: /etc/salt
        - user: root
        - group: root
        - mode: 0770
        - makedirs: True
Make salt-log directory:
    file.directory:
        - name: /var/log/salt
        - user: root
        - group: root
        - mode: 0770
        - makedirs: True
Make salt-cache directory:
    file.directory:
        - name: /var/cache/salt
        - makedirs: True
        - user: root
        - group: root
        - mode: 775
Make salt-run directory:
    file.directory:
        - name: /var/run/salt
        - use:
            - file: Make salt-cache directory

Install salt-master configuration:
    file.managed:
        - template: jinja
        - source: salt://role-master/salt-master.conf
        - name: /etc/salt/master
        - defaults:
            etcd_root_path:
                - "/project/role/master"
                - "/node/%(minion_id)s"
            etcd_service:
                host: {{ grains['fqdn_ip4'] | last }} # FIXME: this host should come from network.interface xref'd with /etc/network-environment
                port: 4001
        - require:
            - file: Make salt-configuration directory
        - user: root
        - group: root
        - mode: 0664

Transfer salt-master build rules:
    # FIXME: this file source should be versioned so that container_version can choose which one
    file.managed:
        - template: jinja
        - source: salt://role-master/salt-master.acb
        - name: "{{ container_path }}/build/salt-master:{{ container_version }}.acb"
        - defaults:
            version: {{ container_version }}
        - require:
            - file: Make container-root build directory
            - file: Install container-build.service
        - user: root
        - group: root
        - mode: 0664

Install openssh-clients in toolbox:
    pkg.installed:
        - pkgs:
            - openssh-clients

    file.symlink:
        - name: {{ salt['user.info'](grains['username']).home }}/.ssh/id_rsa
        - target: {{ pillar['bootstrap']['root'] }}{{ pillar['bootstrap']['remote']['key'] }}
        - force: true
        - makedirs : true
        - mode: 0400

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
            - file: Install openssh-clients in toolbox
            - file: Transfer salt-master build rules
            - file: Install container build script
    file.managed:
        - name: "{{ container_path }}/image/salt-master:{{ container_version }}.aci"
        - user: root
        - group: root
        - mode: 0664

Install salt-master.service:
    file.managed:
        - template: jinja
        - source: salt://role-master/salt-master.service
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
            - file: Build salt-master image
            - file: Install salt-master configuration
        - user: root
        - group: root
        - mode: 0664

### symbolic link for service
Enable systemd multi-user.target wants salt-master.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/salt-master.service
        - target: /etc/systemd/system/salt-master.service
        - require:
            - file: Install salt-master.service
            - sls: seed-etcd
        - makedirs: true

### Scripts for interacting with the salt-master
Install the toolbox script for managing the master:
    file.managed:
        - template: jinja
        - source: salt://role-master/salt-toolbox.command
        - name: /opt/bin/salt-toolbox
        - defaults:
            mounts:
                - "/var/run/dbus"
                - "/etc/systemd"
                - "/etc/salt"
                - "/srv"
                - "/opt"
        - makedirs: true
        - user: root
        - group: root
        - mode: 0755

Create the script for interacting with salt:
    file.managed:
        - template: jinja
        - source: salt://role-master/salt.command
        - name: /opt/bin/salt
        - defaults:
            run_uuid_path: /var/lib/coreos/salt-master.uuid
        - require:
            - file: Install salt-master.service
        - makedirs: true
        - user: root
        - group: root
        - mode: 0755

Create the script for calling salt-run:
    file.symlink:
        - name: /opt/bin/salt-run
        - target: salt
        - require:
            - file: Create the script for interacting with salt
        - makedirs: true

Create the script for calling salt-cp:
    file.symlink:
        - name: /opt/bin/salt-cp
        - target: salt
        - require:
            - file: Create the script for interacting with salt
        - makedirs: true

Create the script for calling salt-key:
    file.symlink:
        - name: /opt/bin/salt-key
        - target: salt
        - require:
            - file: Create the script for interacting with salt
        - makedirs: true

Create the script for calling salt-unity:
    file.symlink:
        - name: /opt/bin/salt-unity
        - target: salt
        - require:
            - file: Create the script for interacting with salt
        - makedirs: true

Create the script for calling salt-cloud:
    file.symlink:
        - name: /opt/bin/salt-cloud
        - target: salt
        - require:
            - file: Create the script for interacting with salt
        - makedirs: true

### Enable the service (note: this is dead because we're just updating the symbolic link, not actually starting anything.)
#salt-master.service:
#    service.dead:
#        - enable: true
