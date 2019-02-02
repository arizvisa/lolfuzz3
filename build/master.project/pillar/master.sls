local:
    # Path to the root filesystem when running inside a container
    root: /media/root
    machine_id: {{ salt['file.read']("/media/root/etc/machine-id").strip() | yaml_dquote }}
