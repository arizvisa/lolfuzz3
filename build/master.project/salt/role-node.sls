Install salt-minion node configuration:
    file.managed:
        - source: salt://salt-minion.conf
        - name: /etc/salt/minion
        - template: jinja
        - defaults:
            conf_path: {{ pillar['configuration']['conf_path'] }}
            file_root_path: {{ pillar['configuration']['file_root_path'] }}
            pillar_root_path: {{ pillar['configuration']['pillar_root_path'] }}
            etcd_root_path:
                - "/project/role/node"
                - "/node/%(minion_id)s"
            etcd_service:
                host: {{ grains['fqdn_ip4'] | last }} # FIXME: this host should come from network.interface xref'd with /etc/network-environment
                port: 4001
            masters_list: []
            role: client
