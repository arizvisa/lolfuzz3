{% set Tools = pillar['configuration']['tools'] %}
{% set SaltContainer = pillar['service']['salt-master'] %}

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
    - stack
    - etcd
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
            - sls: etcd
            - sls: master

Install the script for bootstrapping the master:
    file.managed:
        - template: jinja
        - source: salt://master/salt-bootstrap.command
        - name: {{ Tools.prefix }}/bin/salt-bootstrap

        - context:
            salt_toolbox: {{ Tools.prefix }}/bin/salt-toolbox

        - require:
            - Install the salt-toolbox wrapper

        - mode: 0755
        - makedirs: true

Link the script for calling salt-call:
    file.symlink:
        - name: {{ Tools.prefix }}/bin/salt-call
        - target: salt
        - require:
            - Install the script for interacting with salt-master
        - makedirs: true
