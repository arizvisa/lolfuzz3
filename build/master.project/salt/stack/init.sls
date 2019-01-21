{% set Root = pillar['configuration']['root'] %}
{% set Tools = pillar['configuration']['tools'] %}

# Get the machine-id from the grain, otherwise /etc/machine-id
{% set MachineId = grains.get('machine-id', None) %}
{% if not MachineId %}
    {% set MachineId = salt['file.read']('/'.join([pillar['configuration']['root'], '/etc/machine-id'])).strip() %}
{% endif %}

### Service directories
Make service directory:
    file.directory:
        - name: /srv
        - mode: 0775
        - makedirs: True

### Standard directories that saltstack uses for various things
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

### Scripts for interacting with saltstack
Install the salt-toolbox wrapper:
    file.managed:
        - template: jinja
        - source: salt://stack/salt-toolbox.command
        - name: {{ Tools.prefix }}/bin/salt-toolbox
        - defaults:
            toolbox: /bin/toolbox
            mounts:
                - "/var/run/dbus"
                - "/etc/systemd"
                - "/etc/salt"
                - "/srv"
                - "{{ Tools.prefix }}"
        - mode: 0755
        - makedirs: true
