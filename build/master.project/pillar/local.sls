local:
    # path to root filesystem after bootstrapping with CoreOS' toolbox
    root: /
    machine_id: {{ salt['file.read']("/media/root/etc/machine-id").strip() }}
