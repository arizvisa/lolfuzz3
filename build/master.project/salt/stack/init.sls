# Get the machine-id /etc/machine-id if we're using the bootstrap environment, otherwise use the grain.
{% if grains['minion-role'] == 'master-bootstrap' %}
    {% set Root = pillar['configuration']['root'] %}
    {% set MachineId = salt['file.read']('/'.join([Root, '/etc/machine-id'])).strip() %}
{% else %}
    {% set Root = grains['root'] %}
    {% set MachineId = grains['machine-id'] %}
{% endif %}

### Service directories
Make service directory:
    file.directory:
        - name: /srv
        - mode: 0775
        - makedirs: True

### Standard directories that salt-stack uses for various things
Make salt log directory:
    file.directory:
        - name: /var/log/salt
        - mode: 0770

Make salt config directory:
    file.directory:
        - name: /etc/salt
        - mode: 0770

Make salt pki directory:
    file.directory:
        - name: /etc/salt/pki
        - use:
            - Make salt config directory
        - require:
            - Make salt config directory

Make salt cache directory:
    file.directory:
        - name: /var/cache/salt
        - mode: 0770

Make salt run directory:
    file.directory:
        - name: /var/run/salt
        - mode: 0770

### Salt-stack container
Generate salt-stack container build rules:
    file.managed:
        - template: jinja
        - source: salt://stack/container.acb
        - name: "{{ pillar['service']['container']['path'] }}/build/salt-stack:{{ pillar['container']['salt-stack']['version'] }}.acb"

        - context:
            version: {{ pillar['container']['salt-stack']['version'] }}
            python: {{ pillar['container']['salt-stack']['python'] }}
            pip: {{ pillar['container']['salt-stack']['pip'] }}

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

Build the salt-stack image:
    cmd.run:
        - name: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -- "{{ pillar['configuration']['remote']['host'] }}" sudo -H -E "CONTAINER_DIR={{ pillar['service']['container']['path'] }}" -- "{{ pillar['service']['container']['path'] }}/build.sh" "{{ pillar['service']['container']['path'] }}/build/salt-stack:{{ pillar['container']['salt-stack']['version'] }}.acb"
        - cwd: {{ pillar['service']['container']['path'] }}
        - use_vt: true
        - hide_output: true
        - creates: "{{ pillar['service']['container']['path'] }}/image/salt-stack:{{ pillar['container']['salt-stack']['version'] }}.aci"
        - env:
            - CONTAINER_DIR: {{ pillar['service']['container']['path'] }}
        - require:
            - Generate salt-stack container build rules
            - Install openssh-clients in toolbox
            - Install container build script

Finished building the salt-stack image:
    file.managed:
        - name: "{{ pillar['service']['container']['path'] }}/image/salt-stack:{{ pillar['container']['salt-stack']['version'] }}.aci"
        - mode: 0664
        - replace: false
        - watch:
            - Build the salt-stack image

### Scripts for interacting with salt-stack
Install the salt-toolbox wrapper:
    file.managed:
        - template: jinja
        - source: salt://stack/salt-toolbox.command
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-toolbox

        - defaults:
            toolbox: /bin/toolbox

        - context:
            mounts:
                - "/var/run/dbus"
                - "/etc/systemd"
                - "{{ pillar['configuration']['tools']['prefix'] }}"
                - "/var/cache/salt"
                - "/var/run/salt"
                - "/var/log/salt"
                - "/etc/salt"
                - "/srv"

        - mode: 0755
        - makedirs: true

