### Windows

## (Service) Windows Defender
Stop Microsoft's Windows Defender:
    {% if grains["osrelease"] in ("7", "8") -%}
    service.dead:
        - name: WinDefend
    {% else -%}
    test.succeed_without_changes:
        []
    {% endif %}

Disable Microsoft's Windows Defender:
    {% if grains["osrelease"] in ("7", "8") -%}
    service.disabled:
        - name: WinDefend
    {% else -%}
    cmd.run:
        - name: Set-MpPreference -DisableRealtimeMonitoring $true
        - shell: powershell
    {% endif %}
        - require:
            - Stop Microsoft's Windows Defender

## Hostname information
Set the workgroup:
    system.workgroup:
        - name: {{ pillar["configuration"]["name"] }}

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
            - Disable Microsoft's Windows Defender
        - onchanges_any:
            - Set the hostname
            - Set the computer name
