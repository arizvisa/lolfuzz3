# Get the machine-id /etc/machine-id if we're using the bootstrap environment, otherwise use the grain.
{% if grains['minion-role'] == 'master-bootstrap' %}
    {% set Root = pillar['configuration']['root'] %}
    {% set MachineId = salt['file.read']('/'.join([Root, '/etc/machine-id'])).strip() %}
{% else %}
    {% set Root = grains['root'] %}
    {% set MachineId = grains['machine-id'] %}
{% endif %}

### States to build the salt-minion configuration for managing the salt-master

include:
    - etcd
    - container
    - stack
    - master

Make salt-minion cache directory:
    file.directory:
        - name: /var/cache/salt/minion
        - use:
            - Make salt cache directory
        - require:
            - Make salt cache directory

Make salt-minion pki directory:
    file.directory:
        - name: /etc/salt/pki/minion
        - use:
            - Make salt pki directory
        - require:
            - Make salt pki directory

Make salt-minion run directory:
    file.directory:
        - name: /var/run/salt/minion
        - use:
            - Make salt run directory
        - require:
            - Make salt run directory

Make salt-minion configuration directory:
    file.directory:
        - name: /etc/salt/minion.d
        - use:
            - Make salt config directory
        - require:
            - Make salt config directory

# once we're sure the salt-master.service will run, we can install the salt-minion configuration
Install salt-minion configuration:
    file.managed:
        - template: jinja
        - source: salt://minion/salt-minion.conf
        - name: /etc/salt/minion

        - context:
            machine_id: {{ MachineId }}
            master: localhost

        - use:
            - Install salt-master configuration

        - require:
            - Make salt config directory
            - Initialize the nodes pillar namespace

Install salt-minion.service:
    file.managed:
        - template: jinja
        - source: salt://minion/salt-minion.service
        - name: /etc/systemd/system/salt-minion.service

        - context:
            version: {{ pillar['container']['salt-stack']['Version'] }}
            container_path: {{ pillar['service']['container']['Path'] }}
            image_uuid_path: {{ pillar['service']['container']['Path'] }}/image/salt-stack:{{ pillar['container']['salt-stack']['Version'] }}.aci.id
            run_uuid_path: {{ pillar['service']['salt-minion']['UUID'] }}
            services:
                - host: 127.0.0.1
                  port: 2379
        - use:
            - Transfer salt-stack container build rules
        - require:
            - Install salt-minion configuration
            - Finished building the salt-stack image
            - Install container load script
        - mode: 0664

# systemctl enable the salt-master.service
Enable systemd multi-user.target wants salt-master.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/salt-minion.service
        - target: /etc/systemd/system/salt-minion.service
        - require:
            - Install salt-minion.service
        - makedirs: true

## scripts for interacting with the salt-minion
Install the script for bootstrapping the master:
    file.managed:
        - template: jinja
        - source: salt://minion/salt-bootstrap.command
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-bootstrap

        - context:
            salt_toolbox: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-toolbox

        - require:
            - Install the salt-toolbox wrapper

        - mode: 0755
        - makedirs: true

Install the script for calling salt-call:
    file.symlink:
        - template: jinja
        - source: salt://stack/salt.command
        - name: {{ pillar['configuration']['tools']['prefix'] }}/bin/salt-call

        - defaults:
            rkt: /bin/rkt
            run_uuid_path: {{ pillar['service']['salt-minion']['UUID'] }}

        - require:
            - Finished building the salt-stack image
            - Install salt-minion.service

        - mode: 0755
        - makedirs: true
