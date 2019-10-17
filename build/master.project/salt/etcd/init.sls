{% set Root = pillar["local"]["root"] %}

### Macros to recursively serialize arbitrary data structures into etcd
{% macro project_set_value(root, name, value) %}
Project variable {{ (root + [name]) | join(".") }}:
    etcd.set:
        - name: {{ (root + [name]) | join("/") | yaml_dquote }}
        - value: {{ value }}
        - profile: root_etcd
        - requires:
            - Project key {{ root }}
{% endmacro %}

{% macro project_set_mapping(root, name, value) %}
Project key {{ (root + [name]) | join(".") }}:
    etcd.directory:
        - name: {{ (root + [name]) | join("/") | yaml_dquote }}
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
        - name: {{ salt["config.get"]("root_etcd")["etcd.host"] | yaml_dquote }}
        - port: {{ salt["config.get"]("root_etcd")["etcd.port"] | yaml_encode }}

Register the etcd cluster-size for the machine-id with the v2 discovery protocol:
    etcd.set:
        - name: '{{ pillar["configuration"]["etcd"]["discovery"] }}/{{ pillar["local"]["machine_id"] }}/_config/size'
        - value: {{ pillar["configuration"]["etcd"]["cluster-size"] | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Check firewall rules

### Project configuration
{% set ProjectRoot = pillar["configuration"]["pillar"].split("/") + ["project"] -%}

Project key {{ ProjectRoot | join(".") }}:
    etcd.directory:
        - name: {{ ProjectRoot | join("/") | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Check firewall rules

# Project name
{{ project_set_value(pillar["configuration"]["base"].split("/"), "name", pillar["configuration"]["name"]) }}
{{ project_set_value(ProjectRoot, "name", pillar["configuration"]["name"]) }}

# Project repository
{{ project_set_value(pillar["configuration"]["base"].split("/"), "repository", pillar["configuration"]["path"]) }}
{{ project_set_value(ProjectRoot, "repository", pillar["configuration"]["path"]) }}

# Salt namespace
{{ project_set_value(ProjectRoot, "salt", pillar["configuration"]["salt"]) }}

# Recursively populate the /config key with the defaults specified in the bootstrap pillar
{% set Defaults = pillar["configuration"]["etcd"]["defaults"] %}
{% for item in Defaults %}
    {%- if Defaults[item] is mapping -%}
{{ project_set_mapping(ProjectRoot, item, Defaults[item]) }}
    {%- elif Defaults[item] is sequence and Defaults[item] is not string -%}
{{ raise("Unable to serialize a sequence within the project namespace") }}
    {%- else -%}
{{ project_set_value(ProjectRoot, item, Defaults[item]) }}
    {%- endif -%}
{% endfor %}

### Systemd Services

# systemctl enable the etcd.service
Enable systemd multi-user.target wants etcd.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/etcd.service
        - target: /etc/systemd/system/etcd.service
        - makedirs: true
        - require:
            - Dropin a before requisite to etcd.service

### Etcd requisites

## etcd.service
Make dropin directory for etcd.service:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/etcd.service.d
        - mode: 0755
        - makedirs: true

Dropin a before requisite to etcd.service:
    file.managed:
        - template: jinja
        - source: salt://etcd/requisite-before.dropin
        - name: {{ Root }}/etc/systemd/system/etcd.service.d/15-requisite-before.conf
        - defaults:
            units:
                - flanneld.service
                - salt-master.service
                - salt-minion.service
        - require:
            - Make dropin directory for etcd.service
        - mode: 0644
