{% set ProgramData = salt['environ.get']('ProgramData') %}

include:
    - windows-drivers

Make RamDisk directory:
    file.directory:
        - name: {{ pillar["Drivers"]["RamDisk"]["Path"] }}
        - makedirs: true

Copy ramdisk_setup.exe to target:
    file.managed:
        - name: {{ pillar["Drivers"]["RamDisk"]["Path"] }}/setup.exe
        - source: salt://drivers/ramdisk_setup.exe
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
        - source: salt://drivers/ramdisk-configuration.xml
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

