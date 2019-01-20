{% set MachineID = salt['file.read']('/'.join([pillar['configuration']['root'], '/etc/machine-id'])).strip() %}

Check firewall rules:
    firewall.check:
        - name: {{ salt['config.get']('root_etcd')['etcd.host'] }}
        - port: {{ salt['config.get']('root_etcd')['etcd.port'] }}

Register the etcd cluster-size for the machine-id with the v2 discovery protocol:
    etcd.set:
        - name: "/discovery/{{ MachineID }}/_config/size"
        - value: {{ pillar['configuration']['etcd']['cluster-size'] }}
        - profile: root_etcd
        - requires:
            - Check firewall rules

### Project configuration
Initialize the project configuration:
    etcd.set:
        - name: /config
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - Check firewall rules

## populate the /config key with the defaults specified in the bootstrap pillar
{% for item in pillar['configuration']['defaults'] %}

# Assign a scalar into the /config key
Populate configuration with project variable {{ item }}:
    etcd.set:
        - name: /config/{{ item }}
        - value: {{ pillar['configuration']['defaults'][item] | json | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Initialize the project configuration
{% endfor %}

# This is really for salt, but we're leaving it here
Initialize the nodes pillar:
    etcd.set:
        - name: /node
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - Check firewall rules
