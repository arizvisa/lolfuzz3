{% set Root = pillar["local"]["root"] %}
{% set ConfigurationBootstrapPillar = pillar["configuration"] %}

### Macros to recursively serialize arbitrary data structures into etcd
{% macro etcd_set_value(root, name, value) %}
Configuration variable {{ (root + [name]) | join(".") }}:
    etcd.set:
        - name: {{ (root + [name]) | join("/") | yaml_dquote }}
        - value: {{ value }}
        - profile: root_etcd
        - requires:
            - Configuration key {{ root }}
{% endmacro %}

{% macro etcd_set_mapping(root, name, value) %}
Configuration key {{ (root + [name]) | join(".") }}:
    etcd.directory:
        - name: {{ (root + [name]) | join("/") | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Configuration key {{ root }}

    {%- for item in value -%}
        {%- if value[item] is mapping -%}
{{ etcd_set_mapping(root + [name], item, value[item]) }}
        {%- elif value[item] is sequence and value[item] is not string -%}
{{ raise("Unable to serialize a sequence within the configuration namespace") }}
        {%- else -%}
{{ etcd_set_value(root + [name], item, value[item]) }}
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
        - name: '{{ ConfigurationBootstrapPillar["etcd"]["discovery"] }}/{{ pillar["local"]["machine_id"] }}/_config/size'
        - value: {{ ConfigurationBootstrapPillar["etcd"]["cluster-size"] | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Check firewall rules

### Grab configuration from pillar (files) and write them into extended pillar (etcd)
{% set RootPath = ConfigurationBootstrapPillar["base"].split("/") -%}
{% set ConfigurationPath = ConfigurationBootstrapPillar["base"].split("/") + ["configuration"] -%}
{% set MinionPath = ConfigurationBootstrapPillar["minion"].split("/") -%}

Configuration key {{ RootPath | join(".") }}:
    etcd.directory:
        - name: {{ RootPath | join("/") | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Check firewall rules

Configuration key {{ ConfigurationPath | join(".") }}:
    etcd.directory:
        - name: {{ ConfigurationPath | join("/") | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Configuration key {{ RootPath | join(".") }}

Configuration key {{ MinionPath | join(".") }}:
    etcd.directory:
        - name: {{ MinionPath | join("/") | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Configuration key {{ RootPath | join(".") }}

# Bootstrap master
{{ etcd_set_value(ConfigurationPath, "bootstrap", pillar["local"]["machine_id"]) }}

# Project name
{{ etcd_set_value(ConfigurationPath, "name", ConfigurationBootstrapPillar["name"]) }}

# Project repository uri
{{ etcd_set_value(ConfigurationPath, "repository", ConfigurationBootstrapPillar["path"]) }}

# Salt/Minion namespace paths
{{ etcd_set_value(ConfigurationPath, "base", ConfigurationBootstrapPillar["salt"]) }}
{{ etcd_set_value(ConfigurationPath, "salt", ConfigurationBootstrapPillar["salt"]) }}
{{ etcd_set_value(ConfigurationPath, "minion", ConfigurationBootstrapPillar["minion"]) }}

# Recursively populate the /config key with the defaults specified in the bootstrap pillar
{% set Defaults = ConfigurationBootstrapPillar["defaults"] %}
{% for item in Defaults %}
    {%- if Defaults[item] is mapping -%}
{{ etcd_set_mapping(RootPath, item, Defaults[item]) }}
    {%- elif Defaults[item] is sequence and Defaults[item] is not string -%}
{{ raise("Unable to serialize a sequence within the configuration namespace") }}
    {%- else -%}
{{ etcd_set_value(RootPath, item, Defaults[item]) }}
    {%- endif -%}
{% endfor %}

### Systemd Services

# systemctl enable the etcd.target
Enable systemd multi-user.target wants etcd.targett:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/etcd.target
        - target: /etc/systemd/system/etcd.target
        - makedirs: true
        - require:
            - Dropin a before requisite to etcd.target

### Etcd requisites

## etcd.target
Make dropin directory for etcd.target:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/etcd.target.d
        - mode: 0755
        - makedirs: true

Dropin a before requisite to etcd.target:
    file.managed:
        - template: jinja
        - source: salt://etcd/requisite-before.dropin
        - name: {{ Root }}/etc/systemd/system/etcd.target.d/15-requisite-before.conf
        - defaults:
            units:
                - flanneld.service
                - salt-master.service
                - salt-minion.service
        - require:
            - Make dropin directory for etcd.target
        - mode: 0644
