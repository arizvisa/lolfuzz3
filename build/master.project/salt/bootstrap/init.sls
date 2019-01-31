{% set Root = pillar['local']['root'] %}

# Figure out the external network interface by searching /etc/network-environment
{% set Address = salt['file.grep']('/'.join([Root, '/etc/network-environment']), pattern='^DEFAULT_IPV4=').get('stdout', '').split('=') | last %}
{% set Interface = salt['network.ifacestartswith'](Address) | first %}

### Bootstrap the network environment with the unique machine-id
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
            machine_id: {{ pillar['local']['machine_id'] }}

        - require:
            - sls: master

        - mode: 0664
