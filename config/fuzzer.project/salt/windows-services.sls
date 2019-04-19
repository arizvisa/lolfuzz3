## Services
Stop Microsoft's Windows Defender:
    service.dead:
        - name: WinDefend

Disable Microsoft's Windows Defender:
    service.disabled:
        - name: WinDefend
        - require:
            - Stop Microsoft's Windows Defender

Fallback to Windows Defender exclusions:
    test.succeed_with_changes:
        - onfail:
            - Disable Microsoft's Windows Defender
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
        - onchanges:
            - Fallback to Windows Defender exclusions

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
        - onchanges:
            - Fallback to Windows Defender exclusions

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
        - onchanges:
            - Fallback to Windows Defender exclusions

{% endfor %}
