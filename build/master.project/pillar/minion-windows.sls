local:
    # path to root filesystem (salt installation directory) on windows minion
    root: {{ grains["systempath"] | select("match", ".*salt.*") | list | first }}
    machine_id: {{ grains["id"].rsplit(".", 1)[0] | yaml_dquote }}

    # networking information on windows minion
    interface: {{ grains["hwaddr_interfaces"] | first | yaml_dquote }}
    ip4: {{ grains.get("ipv4", ["127.0.0.1"]) | first | yaml_dquote }}
    ip6: {{ grains.get("ipv6", ["::1"]) | first | yaml_dquote }}

