# path to root filesystem after bootstrapping with CoreOS' toolbox
local:
    root: /
    machine_id: {{ salt['file.read']("/media/root/etc/machine-id').strip() }}
