{% set Root = pillar["local"]["root"] %}

### Bootstrap the network environment with the unique machine-id
Generate bootstrap-environment from machine-id:
    file.managed:
        - template: jinja
        - source: salt://bootstrap/bootstrap.env
        - name: '{{ Root }}/etc/bootstrap-environment'
        - defaults:
            ip4: {{ pillar["local"]["ip4"] | yaml_dquote }}
            ip6: {{ pillar["local"]["ip6"] | yaml_dquote }}
            machine_id: {{ pillar["local"]["machine_id"] | yaml_dquote }}
        - mode: 0664
