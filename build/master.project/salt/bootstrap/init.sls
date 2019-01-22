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

### Bootstrap the network environment with the unique MachineId

include:
    - master

Generate bootstrap-environment from machine-id:
    file.managed:
        - template: jinja
        - source: salt://bootstrap/bootstrap.env
        - name: {{ Root }}/etc/bootstrap-environment

        - context:
            ip4: {{ grains['ip4_interfaces'][Interface] | first }}
            ip6: {{ grains['ip6_interfaces'][Interface] | first }}
            machine_id: {{ MachineId }}

        - require:
            - sls: master

        - mode: 0664
