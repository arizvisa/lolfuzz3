{% if grains["os_family"] == "Windows" -%}
## Windows
Set the workgroup:
    system.workgroup:
        - name: {{ pillar["project"]["name"] }}

Set the hostname:
    system.hostname:
        - name: {{ grains["id"].rsplit(".", 1)[0] }}

Set the computer name:
    system.computer_name:
        - name: {{ grains["id"].rsplit(".", 1)[0] }}

Reboot after name change:
    event.send:
        - name: salt/minion/{{ grains["id"] }}/log
        - data:
            level: info
            message: "Rebooting due to name change"
        - onchanges_any:
            - Set the hostname
            - Set the computer name

    system.reboot:
        - message: Rebooting due to hostame
        - timeout: 0
        - only_on_pending_reboot: false
        - require:
            - Set the workgroup
        - onchanges_any:
            - Set the hostname
            - Set the computer name

{% else -%}
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

{%- endif %}