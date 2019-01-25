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

Make salt-cloud profiles directory:
    file.directory:
        - name: /srv/cloud
        - mode: 1775
        - require:
            - Make service directory
        - use:
            - Make service directory

Install salt-cloud profiles directory:
    file.symlink:
        - name: /etc/salt/cloud.profiles.d
        - target: /srv/cloud
        - require:
            - Make salt configuration directory
            - Make salt-cloud profiles directory

Install default cloud configuration:
    file.managed:
        - source: salt://cloud/default.conf
        - name: /srv/cloud/default.conf
        - mode: 0664
        - require:
            - Make salt-cloud profiles directory

Install saltify cloud configuration:
    file.managed:
        - template: jinja
        - source: salt://cloud/profiles.conf
        - name: /srv/cloud/profiles.conf
        - defaults:
            profiles:
                - name: base
                  configuration:
                      minion:
                          master: {{ grains['ip4_interfaces'][Interface] | first }}
                      driver: saltify
                      force_minion_config: true
                      delete_sshkeys: true
                      ssh_agent: true
                      sync_after_install: all
                      shutdown_on_destroy: true
                      remove_config_on_destroy: true
        - require:
            - Make salt-cloud profiles directory
        - mode: 0664

