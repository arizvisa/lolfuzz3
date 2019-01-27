# Get the machine-id /etc/machine-id if we're using the bootstrap environment, otherwise use the grain.
{% if grains['minion-role'] == 'master-bootstrap' %}
    {% set Root = pillar['configuration']['root'] %}
    {% set MachineId = salt['file.read']('/'.join([Root, '/etc/machine-id'])).strip() %}
{% else %}
    {% set Root = grains['root'] %}
    {% set MachineId = grains['machine-id'] %}
{% endif %}

# Figure out the external network interface by searching /etc/network-environment
{% set Address = salt['file.grep']('/'.join([Root, '/etc/network-environment']), pattern='^DEFAULT_IPV4=').get('stdout', '').split('=') | last %}
{% set Interface = salt['network.ifacestartswith'](Address) | first %}

include:
    - stack

### salt-cloud configuration
Install salt-cloud configuration:
    file.managed:
        - template: jinja
        - source: salt://cloud/cloud.conf
        - name: /etc/salt/cloud
        - defaults:
            log_level: info
            pool_size: 10
            minion:
                master: {{ grains['ip4_interfaces'][Interface] | first }}
        - require:
            - Make salt configuration directory
        - mode: 0664                

### Service directories
Make salt-cloud configuration directory:
    file.directory:
        - name: /srv/cloud
        - mode: 1775
        - require:
            - Make service directory
        - use:
            - Make service directory

Make salt-cloud providers directory:
    file.directory:
        - name: /srv/cloud/providers
        - require:
            - Make salt-cloud configuration directory
        - use:
            - Make salt-cloud configuration directory

Make salt-cloud profiles directory:
    file.directory:
        - name: /srv/cloud/profiles
        - require:
            - Make salt-cloud configuration directory
        - use:
            - Make salt-cloud configuration directory

## Installation of service directories
Install salt-cloud providers directory:
    file.symlink:
        - name: /etc/salt/cloud.providers.d
        - target: /srv/cloud/providers
        - require:
            - Make salt configuration directory
            - Make salt-cloud providers directory

Install salt-cloud profiles directory:
    file.symlink:
        - name: /etc/salt/cloud.profiles.d
        - target: /srv/cloud/profiles
        - require:
            - Make salt configuration directory
            - Make salt-cloud profiles directory

### Example configurations
Install an example cloud provider:
    file.managed:
        - template: jinja
        - source: salt://cloud/providers.conf
        - name: /srv/cloud/providers/default.conf
        - defaults:
              providers:
                  {}
        - require:
            - Make salt-cloud providers directory
        - mode: 0664

Install an example cloud profile:
    file.managed:
        - template: jinja
        - source: salt://cloud/profiles.conf
        - name: /srv/cloud/profiles/default.conf
        - defaults:
              profiles:
                  {}
        - require:
            - Make salt-cloud profiles directory
        - mode: 0664

