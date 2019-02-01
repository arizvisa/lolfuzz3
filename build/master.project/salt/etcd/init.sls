{% set Root = pillar['local']['root'] %}

### Macros to recursively serialize arbitrary data structures into etcd
{% macro project_set_value(root, name, value) %}
Project variable {{ (root + [name]) | join('.') }}:
    etcd.set:
        - name: {{ (root + [name]) | join('/') }}
        - value: {{ value }}
        - profile: root_etcd
        - requires:
            - Project key {{ root }}
{% endmacro %}

{% macro project_set_mapping(root, name, value) %}
Project key {{ (root + [name]) | join('.') }}:
    etcd.directory:
        - name: {{ (root + [name]) | join('/') }}
        - profile: root_etcd
        - requires:
            - Project key {{ root }}

    {%- for item in value -%}
        {%- if value[item] is mapping -%}
{{ project_set_mapping(root + [name], item, value[item]) }}
        {%- elif value[item] is sequence and value[item] is not string -%}
{{ raise("Unable to serialize a sequence within the project namespace") }}
        {%- else -%}
{{ project_set_value(root + [name], item, value[item]) }}
        {%- endif -%}
    {%- endfor -%}
{% endmacro %}

### States to configure etcd and seed it with its initial configuration

Check firewall rules:
    firewall.check:
        - name: {{ salt['config.get']('root_etcd')['etcd.host'] }}
        - port: {{ salt['config.get']('root_etcd')['etcd.port'] }}

Register the etcd cluster-size for the machine-id with the v2 discovery protocol:
    etcd.set:
        - name: "{{ pillar['configuration']['etcd']['discovery'] }}/{{ pillar['local']['machine_id'] }}/_config/size"
        - value: {{ pillar['configuration']['etcd']['cluster-size'] }}
        - profile: root_etcd
        - requires:
            - Check firewall rules

### Project configuration
{% set ProjectRoot = ['', 'config'] -%}
Project key {{ ProjectRoot | join('.') }}:
    etcd.directory:
        - name: {{ ProjectRoot | join('/') }}
        - profile: root_etcd
        - requires:
            - Check firewall rules

# recursively populate the /config key with the defaults specified in the bootstrap pillar
{% for item in pillar['configuration']['defaults'] %}
    {%- if pillar['configuration']['defaults'][item] is mapping -%}
{{ project_set_mapping(['', 'config'], item, pillar['configuration']['defaults'][item]) }}
    {%- elif pillar['configuration']['defaults'][item] is sequence and pillar['configuration']['defaults'][item] is not string -%}
{{ raise("Unable to serialize a sequence within the project namespace") }}
    {%- else -%}
{{ project_set_value(['', 'config'], item, pillar['configuration']['defaults'][item]) }}
    {%- endif -%}
{% endfor %}

### Systemd Services

# systemctl enable the etcd-member.service
Enable systemd multi-user.target wants etcd.serice:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/etcd.service
        - target: /etc/systemd/system/etcd.service
        - makedirs: true
        - require:
            - Dropin a before requisite to etcd.service

# systemctl enable the etcd-master.service
Enable systemd multi-user.target wants etcd-master.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/etcd-master.service
        - target: /etc/systemd/system/etcd-master.service
        - makedirs: true
        - require:
            - Dropin a before requisite to etcd-master.service

### Etcd requisites

## etcd.service
Make dropin directory for etcd.service:
    file.directory:
        - name: /etc/systemd/system/etcd.service.d
        - mode: 0755
        - makedirs: true

Dropin a before requisite to etcd.service:
    file.managed:
        - template: jinja
        - source: salt://etcd/requisite-before.dropin
        - name: /etc/systemd/system/etcd.service.d/15-requisite-before.conf
        - defaults:
            units:
                - flanneld.service
                - salt-master.service
                - salt-minion.service
        - require:
            - Make dropin directory for etcd.service
        - mode: 0644

## etcd-master.service
Make dropin directory for etcd-master.service:
    file.directory:
        - name: /etc/systemd/system/etcd-master.service.d
        - mode: 0755
        - makedirs: true

Dropin a before requisite to etcd-master.service:
    file.managed:
        - template: jinja
        - source: salt://etcd/requisite-before.dropin
        - name: /etc/systemd/system/etcd-master.service.d/15-requisite-before.conf
        - defaults:
            units:
                - flanneld.service
                - salt-master.service
                - salt-minion.service
        - require:
            - Make dropin directory for etcd-master.service
        - mode: 0644
