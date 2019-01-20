{% set MachineID = salt['file.read']('/'.join([pillar['bootstrap']['root'], '/etc/machine-id'])).strip() %}
{% set tools = pillar['master']['tools'] %}

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
        - mode: 0770:

Make salt run directory:
    file.directory:
        - name: /var/run/salt
        - mode: 0770:

### Scripts for interacting with saltstack
Install the salt-toolbox wrapper:
    file.managed:
        - template: jinja
        - source: salt://stack/salt-toolbox.command
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

