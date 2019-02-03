# Grab the address from setup-network-environment
{% set ip4 = salt["file.grep"]("/media/root/etc/network-environment", pattern="^DEFAULT_IPV4=").get("stdout", "").split("=", 1) | last %}
{% set interface = (salt["file.grep"]("/media/root/etc/network-environment", pattern="=" + ip4).get("stdout", "").split("=", 1)[0].split("_", 1) | first).lower() %}

# Use the address with salt to get interface
{% set SaltIntf = salt["network.ifacestartswith"](ip4) | first %}

local:
    interface: {{ SaltIntf | yaml_dquote }}
    ip4: {{ grains["ip4_interfaces"][SaltIntf] | last | yaml_dquote }}
    ip6: {{ grains["ip6_interfaces"][SaltIntf] | last | yaml_dquote }}
