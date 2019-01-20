{% set Root = pillar['bootstrap']['root'] %}

# Get the machine-id from /etc/machine-id
{% set MachineID = salt['file.read']('/'.join([Root, '/etc/machine-id'])).strip() %}

# Figure out the external network interface by searching /etc/network-environment
{% set Address = salt['file.grep']('/'.join([Root, '/etc/network-environment']), pattern='^DEFAULT_IPV4=').get('stdout', '').split('=') | last %}
{% if Address %}
    {% set Interface = salt['network.ifacestartswith'](Address) | first %}
{% else %}
    {% set Interface = "lo" %}
{% endif %}

include:
    - master

Generate bootstrap-environment from machine-id:
    file.managed:
        - template jinja
        - source: salt://bootstrap/bootstrap.env
        - name: {{ Root }}/etc/bootstrap-environment
        - defaults:
            ip4: {{ grains['ip4_interfaces'][Interface] | first }}
            ip6: {{ grains['ip6_interfaces'][Interface] | first }}
            machine_id: {{ MachineID }}
        - require:
            - sls: master
        - mode: 0664
