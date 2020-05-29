## Linux (other)
Set the hostname:
    network.system:
        - enabled: true
        - hostname: {{ grains["id"].rsplit(".", 1)[0] }}.{{ pillar["configuration"]["name"] }}
        - apply_hostname: true
        - domainname: {{ pillar["configuration"]["name"] }}
        - searchdomain: {{ pillar["configuration"]["name"] }}
        - nozeroconf: true
        - retain_settings: true
