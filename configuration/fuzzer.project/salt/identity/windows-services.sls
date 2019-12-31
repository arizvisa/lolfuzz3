## Services
Stop Microsoft's Windows Defender:
    {% if grains["osrelease"] in ("7", "8", "8.1") -%}
    service.dead:
        - name: WinDefend
    {% else -%}
    test.succeed_without_changes:
        []
    {% endif %}

Disable Microsoft's Windows Defender:
    {% if grains["osrelease"] in ("7", "8", "8.1") -%}
    service.disabled:
        - name: WinDefend
    {% else -%}
    cmd.run:
        - name: Set-MpPreference -DisableRealtimeMonitoring $true
        - shell: powershell
    {% endif %}
        - require:
            - Stop Microsoft's Windows Defender

Add the salt path to the exclusions for Windows Defender:
    {% if grains["osrelease"] in ("7", "8", "8.1") %}
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths
        - vname: {{ grains["saltpath"].rsplit("\\", 4)[0] | yaml_dquote }}
        - vtype: REG_DWORD
        - vdata: 0x00000000
    {% else %}
    cmd.run:
        - name: Add-MpPreference -ExclusionPath "{{ grains["saltpath"].rsplit("\\", 4)[0] }}"
        - shell: powershell
    {% endif %}

Add the drivers path to the exclusions for Windows Defender:
    {% if grains["osrelease"] in ("7", "8", "8.1") %}
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths
        - vname: {{ pillar["Drivers"]["Path"] | replace("/", "\\") | yaml_dquote }}
        - vtype: REG_DWORD
        - vdata: 0x00000000
    {% else %}
    cmd.run:
        - name: Add-MpPreference -ExclusionPath "{{ pillar["Drivers"]["Path"] | replace("/", "\\") }}"
        - shell: powershell
    {% endif %}

{% for disk in pillar["Drivers"]["RamDisk"]["Disks"] %}
Add the ramdisk path ({{ disk.drive }}:\) to the exclusions for Windows Defender:
    {% if grains["osrelease"] in ("7", "8", "8.1") %}
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths
        - vname: {{ (disk.drive + ":\\") | yaml_dquote }}
        - vtype: REG_DWORD
        - vdata: 0x00000000
    {% else %}
    cmd.run:
        - name: Add-MpPreference -ExclusionPath "{{ disk.drive + ":\\" }}"
        - shell: powershell
    {% endif %}

{% endfor %}
