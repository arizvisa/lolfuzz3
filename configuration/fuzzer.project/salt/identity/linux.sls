## Linux (other)
Set the hostname:
    network.system:
        - enabled: true
        - hostname: {{ grains["id"].rsplit(".", 1)[0] }}.{{ pillar["project"]["name"] }}
        - apply_hostname: true
        - domainname: {{ pillar["project"]["name"] }}
        - searchdomain: {{ pillar["project"]["name"] }}
        - nozeroconf: true
        - retain_settings: true
