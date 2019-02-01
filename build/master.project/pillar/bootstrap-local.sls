local:
    # Path to root filesystem while bootstrapping with CoreOS' toolbox
    root: /media/root
    machine_id: {{ salt['file.read']("/media/root/etc/machine-id").strip() }}
