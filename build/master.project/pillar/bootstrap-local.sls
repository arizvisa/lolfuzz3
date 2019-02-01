{% set Address = salt['file.grep']('/media/root/etc/network-environment', pattern='^DEFAULT_IPV4=').get('stdout', '').split('=') | last %}

# path to root filesystem while bootstrapping with CoreOS' toolbox
local:
    root: /media/root
    machine_id: {{ salt['file.read']("/media/root/etc/machine-id").strip() }}
    interface: {{ salt['network.ifacestartswith'](Address) | first }}
