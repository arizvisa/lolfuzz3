{% set Root = pillar['configuration']['root'] %}

# Get the machine-id from the grain, otherwise /etc/machine-id
{% set MachineId = grains.get('machine-id', None) %}
{% if not MachineId %}
    {% set MachineId = salt['file.read']('/'.join([pillar['configuration']['root'], '/etc/machine-id'])).strip() %}
{% endif %}

# Figure out the external network interface by searching /etc/network-environment
{% set Address = salt['file.grep']('/'.join([Root, '/etc/network-environment']), pattern='^DEFAULT_IPV4=').get('stdout', '').split('=') | last %}
{% if Address %}
    {% set Interface = salt['network.ifacestartswith'](Address) | first %}
{% else %}
    {% set Interface = "lo" %}
{% endif %}

### Bootstrap the network environment with the unique MachineId

include:
    - master

Generate bootstrap-environment from machine-id:
    file.managed:
        - template: jinja
        - source: salt://bootstrap/bootstrap.env
        - name: {{ Root }}/etc/bootstrap-environment
        - defaults:
            ip4: {{ grains['ip4_interfaces'][Interface] | first }}
            ip6: {{ grains['ip6_interfaces'][Interface] | first }}
            machine_id: {{ MachineId }}
        - require:
            - sls: master
        - mode: 0664
