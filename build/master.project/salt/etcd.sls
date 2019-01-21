{% set Root = pillar['configuration']['root'] %}

# Get the machine-id from the grain, otherwise /etc/machine-id
{% set MachineId = grains.get('machine-id', None) %}
{% if not MachineId %}
    {% set MachineId = salt['file.read']('/'.join([Root, '/etc/machine-id'])).strip() %}
{% endif %}

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
    etcd.set:
        - name: {{ (root + [name]) | join('/') }}
        - value: null
        - directory: true
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
        - name: "/discovery/{{ MachineId }}/_config/size"
        - value: {{ pillar['configuration']['etcd']['cluster-size'] }}
        - profile: root_etcd
        - requires:
            - Check firewall rules

### Project configuration
{% set ProjectRoot = ['', 'config'] -%}
Project key {{ ProjectRoot | join('.') }}:
    etcd.set:
        - name: {{ ProjectRoot | join('/') }}
        - value: null
        - directory: true
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
