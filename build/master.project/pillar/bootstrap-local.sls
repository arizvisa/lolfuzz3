{% set ip4 = salt['file.grep']('/media/root/etc/network-environment', pattern='^DEFAULT_IPV4=').get('stdout', '').split('=', 1) | last %}
{% set interface = (salt['file.grep']('/media/root/etc/network-environment', pattern='=' + ip4).get('stdout', '').split('=', 1)[0].split('_', 1) | first).lower() %}

# path to root filesystem while bootstrapping with CoreOS' toolbox
local:
    root: /media/root
    machine_id: {{ salt['file.read']("/media/root/etc/machine-id").strip() }}

    interface: {{ interface }}
    ip4: {{ ip4 }}
    ip6: {{ grains['ip6_interfaces']['interface'] | last }}
