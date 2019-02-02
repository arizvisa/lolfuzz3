local:
    # path to root filesystem on windows minion
    root: {{ grains['saltpath'].rsplit('\\', 4)[0] | yaml_dquote }}
    machine_id: {{ grains['id'].rsplit('.', 1)[0] | yaml_dquote }}

    # networking information on windows minion
    interface: {{ grains['hwaddr_interfaces'] | first | yaml_dquote }}
    ip4: {{ grains['ipv4'] | first | yaml_dquote }}
    ip6: {{ grains['ipv6'] | first | yaml_dquote }}

