local:
    # path to root filesystem on a linux minion
    root: /
    machine_id: {{ grains['id'].rsplit('.', 1)[0] }}

    # networking information on linux minion
    interface: {{ grains['hwaddr_interfaces'] | first | yaml_dquote }}
    ip4: {{ grains['ipv4'] | first | yaml_dquote }}
    ip6: {{ grains['ipv6'] | first | yaml_dquote }}
