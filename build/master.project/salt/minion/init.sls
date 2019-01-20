{% set MachineID = salt['file.read']('/'.join([pillar['bootstrap']['root'], '/etc/machine-id'])).strip() %}
{% set tools = pillar['master']['tools'] %}

include:
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

# once we're sure the salt-master.service will run, we can install the salt-minion configuration
Install salt-minion configuration:
    file.managed:
        - template: jinja
        - source: salt://minion/salt-minion.conf
        - name: /etc/salt/minion
        - context:
            machine_id: {{ MachineID }}
            master: localhost
            log_level: info
        - use:
            - Install salt-master configuration
        - require:
            - sls: etcd
            - Finished building the salt-master image
            - Enable systemd multi-user.target wants salt-master.service

Install the script for bootstrapping the master:
    file.managed:
        - template: jinja
        - source: salt://master/salt-bootstrap.command
        - name: {{ tools.prefix }}/bin/salt-bootstrap
        - defaults:
            salt_toolbox: {{ tools.prefix }}/bin/salt-toolbox
        - require:
            - Install the salt-toolbox wrapper
        - mode: 0755
        - makedirs: true

Link the script for calling salt-call:
    file.symlink:
        - name: {{ tools.prefix }}/bin/salt-call
        - target: salt
        - require:
            - Install the script for interacting with salt-master:
        - makedirs: true
