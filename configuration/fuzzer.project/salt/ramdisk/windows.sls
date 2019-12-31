{% set ProgramData = salt["environ.get"]("ProgramData") %}
{% set ProgramFiles = salt["environ.get"]("PROGRAMW6432", default=salt["environ.get"]("PROGRAMFILES")) %}

include:
    - identity.windows-drivers

Make RamDisk directory:
    file.directory:
        - name: {{ pillar["Drivers"]["RamDisk"]["Path"] }}
        - makedirs: true
        - require:
            - Create the base driver directory

Copy ramdisk_setup.exe to target:
    file.managed:
        - name: {{ pillar["Drivers"]["RamDisk"]["Path"] }}/setup.exe
        - source: salt://ramdisk/ramdisk_setup.exe
        - makedirs: true
        - require:
            - Make RamDisk directory

Install SoftPerfect RAM Disk:
    cmd.run:
        - cwd: {{ pillar["Drivers"]["RamDisk"]["Path"] }}
        - name: setup.exe /silent /log="{{ pillar["Drivers"]["RamDisk"]["Path"] }}/setup.log"
        - creates:
            - {{ pillar["Drivers"]["RamDisk"]["Path"] }}/setup.log
        - require:
            - Make RamDisk directory
            - Copy ramdisk_setup.exe to target

Install the ramdisk configuration:
    file.managed:
        - template: jinja
        - name: {{ ProgramData }}/SoftPerfect/RamDiskWS/RamDiskWS.xml
        - source: salt://ramdisk/ramdisk-configuration.xml
        - defaults:
            useraccess:  true
            locallinks: false
            trayicon: true
            alloweject: true

        - require:
            - Install SoftPerfect RAM Disk

Install volume check tool:
    file.managed:
        - name: {{ pillar["Drivers"]["Tools"] }}/Check-Volume.ps1
        - contents: |
            param(
                [Parameter(Mandatory=$true)[string]$Drive
            )
            $volume = Get-WmiObject -Class Win32_Volume | Where-Object {$_.Name -eq ($Drive + ":\")}
            if ( -not $volume ) {
                Exit 1
            }
            Exit 0

        - require:
            - Make driver tools directory

Install volume unmount tool:
    file.managed:
        - name: {{ pillar["Drivers"]["Tools"] }}/Unmount-Volume.ps1
        - contents: |
            param(
                [Parameter(Mandatory=$true)[string]$Drive,
                [bool]$Force = $false
            )
            $volume = Get-WmiObject -Class Win32_Volume | Where-Object {$_.Name -eq ($Drive + ":\")}
            if ( -not $volume ) {
                Exit 1
            }
            $volume.DriveLetter = $null
            $volume.Put()
            $volume.Dismount($Force, $false)

        - require:
            - Make driver tools directory

Install the ramdisk disks configuration:
    file.managed:
        - template: jinja
        - name: {{ pillar["Drivers"]["RamDisk"]["Path"] }}/Disks.xml
        - source: salt://ramdisk/ramdisk-disks.xml
        - defaults:
              boot:
                {% for disk in pillar["Drivers"]["RamDisk"]["Disks"] %}
                - drive: {{ disk.drive | yaml_squote }}
                  filesystem: {{ disk.filesystem | yaml_squote }}
                  size: {{ disk.size | yaml_encode }}
                  filename: ''
                  label: {{ disk.label | yaml_squote }}
                  save: false
                  removable: true
                  compressed: false
                  flush:
                      enable: false
                      time: 1
                  emulation: false
                  numanode: 0
                  specnuma: false
                {% endfor %}
        - require:
            - Make RamDisk directory

## Use Windows Explorer to unmount all of the RamDisk volumes
{% for disk in pillar["Drivers"]["RamDisk"]["Disks"] %}
Unmount drive {{ disk.drive }}:
    cmd.run:
        - shell: powershell
        - onlyif: '{{ pillar["Drivers"]["Tools"] }}/Check-Volume.ps1 -Drive "{{ disk.drive }}"'
        - name: '{{ pillar["Drivers"]["Tools"] }}/Unmount-Volume.ps1 -Force -Drive "{{ disk.drive }}"'
        - require:
            - Install volume check tool
            - Install volume unmount tool
        - onchanges:
            - Install the ramdisk disks configuration
{%- endfor %}

## Unmount volumes from SoftPerfect
Unmount all of our ramdisk volumes:
    cmd.run:
        - cwd: '{{ ProgramFiles }}\SoftPerfect RAM Disk'
        - name: 'ramdiskws -unmount:"all"'
        - bg: true
        - onchanges:
            - Install the ramdisk disks configuration
        - require:
{% for disk in pillar["Drivers"]["RamDisk"]["Disks"] %}
            - Unmount drive {{ disk.drive }}
{% endfor %}

(Wait) Unmount all of our ramdisk volumes:
    module.run:
        - test.sleep:
            - length: {{ pillar["Drivers"]["RamDisk"]["Timeout"] | yaml_encode }}
        - require:
            - Unmount all of our ramdisk volumes

## Flush disk configuration from SoftPerfect
Flush ramdisk configuration:
    cmd.run:
        - cwd: '{{ ProgramFiles }}\SoftPerfect RAM Disk'
        - name: 'ramdiskws -del:"all"'
        - bg: true
        - onchanges:
            - Install the ramdisk disks configuration
        - require:
            - Install SoftPerfect RAM Disk
            - (Wait) Unmount all of our ramdisk volumes

(Wait) Flush ramdisk configuration:
    module.run:
        - test.sleep:
            - length: {{ pillar["Drivers"]["RamDisk"]["Timeout"] | yaml_encode }}
        - require:
            - Flush ramdisk configuration

## Re-import the new disk configuration into SoftPerfect
Import our disks configuration:
    cmd.run:
        - cwd: '{{ ProgramFiles }}\SoftPerfect RAM Disk'
        - name: 'ramdiskws -import:"{{ pillar["Drivers"]["RamDisk"]["Path"] }}/Disks.xml"'
        - bg: true
        - onchanges:
            - Install the ramdisk disks configuration
        - require:
            - Install SoftPerfect RAM Disk
            - (Wait) Flush ramdisk configuration

(Wait) Import our disks configuration:
    module.run:
        - test.sleep:
            - length: {{ pillar["Drivers"]["RamDisk"]["Timeout"] | yaml_encode }}
        - require:
            - Import our disks configuration

## Reboot since SoftPerfect blocks
Reboot machine to load ramdisk:
    system.reboot:
        - message: Reboot to load ramdisk
        - timeout: 0
        - only_on_pending_reboot: false
        - onchanges:
            - Install the ramdisk disks configuration
        - require:
            - (Wait) Import our disks configuration
