{% set Root = pillar['local']['root'] %}
{% set Interface = pillar['local']['interface'] %}

### Bootstrap the network environment with the unique machine-id
Generate bootstrap-environment from machine-id:
    file.managed:
        - template: jinja
        - source: salt://bootstrap/bootstrap.env
        - name: {{ Root }}/etc/bootstrap-environment
        - defaults:
            ip4: {{ grains['ip4_interfaces'][Interface] | first }}
            ip6: {{ grains['ip6_interfaces'][Interface] | first }}
            machine_id: {{ pillar['local']['machine_id'] }}
        - mode: 0664
