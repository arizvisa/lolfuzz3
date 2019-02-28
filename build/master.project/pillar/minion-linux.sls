local:
    # path to root filesystem on a linux minion
    root: /
    machine_id: {{ grains["id"].rsplit(".", 1)[0] | yaml_dquote }}

    # networking information on linux minion
    interface: {{ grains.get("hwaddr_interfaces", ["lo"]) | first | yaml_dquote }}
    ip4: {{ grains.get("ipv4", ["127.0.0.1"]) | first | yaml_dquote }}
    ip6: {{ grains.get("ipv6", ["::1"]) | first | yaml_dquote }}
