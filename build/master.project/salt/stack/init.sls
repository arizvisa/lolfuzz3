{% set Root = pillar["local"]["root"] %}

include:
    - container

### Service directories
Make service directory:
    file.directory:
        - name: /srv
        - mode: 0775
        - makedirs: true

### Standard directories that salt-stack uses for various things
Make salt log directory:
    file.directory:
        - name: '{{ Root }}/var/log/salt'
        - mode: 0770

Make salt configuration directory:
    file.directory:
        - name: '{{ Root }}/etc/salt'
        - mode: 0770

Make salt pki directory:
    file.directory:
        - name: '{{ Root }}/etc/salt/pki'
        - use:
            - Make salt configuration directory
        - require:
            - Make salt configuration directory

Make salt cache directory:
    file.directory:
        - name: '{{ Root }}/var/cache/salt'
        - mode: 0770

Make salt run directory:
    file.directory:
        - name: '{{ Root }}/var/run/salt'
        - mode: 0770

### Salt-stack container
Generate salt-stack container build rules:
    file.managed:
        - template: jinja
        - source: salt://stack/container.acb
        - name: '{{ Root }}/{{ pillar["service"]["container"]["paths"]["build"] }}/salt-stack:{{ pillar["container"]["salt-stack"]["version"] }}.acb'

        - context:
            bootstrap: {{ pillar["container"]["salt-stack"]["bootstrap"] | yaml_dquote }}
            version: {{ pillar["container"]["salt-stack"]["version"] | yaml_dquote }}
            python: {{ pillar["container"]["salt-stack"]["python"] | yaml_dquote }}
            pip: {{ pillar["container"]["salt-stack"]["pip"] | yaml_dquote }}

            commands:
                - run: dnf -y --setopt=fastestmirror=true --setopt=retries=0 upgrade

        - defaults:
            volumes:
                dbus-socket:
                    source: /var/run/dbus
                    mount: /var/run/dbus
                run-systemd:
                    source: /var/run/systemd
                    mount: /var/run/systemd
                media-root:
                    source: /
                    mount: /media/root
                salt-cache:
                    source: /var/cache/salt
                    mount: /var/cache/salt
                salt-logs:
                    source: /var/log/salt
                    mount: /var/log/salt
                salt-run:
                    source: /var/run/salt
                    mount: /var/run/salt
                salt-etc:
                    source: /etc/salt
                    mount: /etc/salt
                salt-srv:
                    source: /srv
                    mount: /srv

        - require:
            - Make container-root build directory
            - Install container-build.service
        - mode: 0664

# building the salt-stack container
Build the salt-stack image:
    cmd.run:
        - name: /usr/bin/ssh -i "{{ Root }}{{ pillar["toolbox"]["self-service"]["key"] }}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -- {{ pillar["toolbox"]["self-service"]["host"] | yaml_squote }} sudo -H -E "CONTAINER_DIR={{ pillar["service"]["container"]["paths"]["base"] }}" -- "{{ pillar["service"]["container"]["paths"]["base"] }}/build.sh" "{{ pillar["service"]["container"]["paths"]["build"] }}/salt-stack:{{ pillar["container"]["salt-stack"]["version"] }}.acb"
        - cwd: '{{ Root }}/{{ pillar["service"]["container"]["paths"]["base"] }}'
        - use_vt: true
        - hide_output: true
        - creates: '{{ Root }}/{{ pillar["service"]["container"]["paths"]["image"] }}/salt-stack:{{ pillar["container"]["salt-stack"]["version"] }}.aci'
        - env:
            - CONTAINER_DIR: {{ pillar["service"]["container"]["paths"]["base"] | yaml_dquote }}
        - require:
            - Generate salt-stack container build rules
            - Install container build script

Finished building the salt-stack image:
    file.managed:
        - name: '{{ Root }}/{{ pillar["service"]["container"]["paths"]["image"] }}/salt-stack:{{ pillar["container"]["salt-stack"]["version"] }}.aci'
        - mode: 0664
        - replace: false
        - watch:
            - Build the salt-stack image

### Scripts for interacting with salt-stack
Install the salt-toolbox wrapper:
    file.managed:
        - template: jinja
        - source: salt://scripts/salt-toolbox.command
        - name: /opt/sbin/salt-toolbox

        - defaults:
            toolbox: /bin/toolbox

        - context:
            mounts:
                - /var/run/dbus
                - /etc/systemd
                - /opt
                - /var/cache/salt
                - /var/run/salt
                - /var/log/salt
                - /srv

        - mode: 0755
        - makedirs: true

