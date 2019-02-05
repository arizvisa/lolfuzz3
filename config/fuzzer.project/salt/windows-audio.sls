include:
    - windows-drivers

Make audio driver path:
    file.directory:
        - name: {{ pillar["Drivers"]["Audio"]["Path"] }}
        - makedirs: true

Extract audio drivers on target:
    archive.extracted:
        - name: {{ pillar["Drivers"]["Audio"]["Path"] }}
        - source: salt://drivers/vadrv.zip
        - archive_format: zip
        - enforce_toplevel: false
        - require:
            - Make audio driver path

Extract certificate from audio driver:
    cmd.run:
        - shell: powershell
        - cwd: {{ pillar["Drivers"]["Audio"]["Path"] }}
        - onlyif: '{{ pillar["Drivers"]["Tools"] }}/Find-Device.ps1 -Id "VAud_WDM"'
        {% if grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" -%}
        - name: '{{ pillar["Drivers"]["Tools"] }}/Extract-Certificate.ps1 -Source "vadrv/vaud_wdmx64.cat" -Output "vadrv.cer"'
        {% else -%}
        - name: '{{ Tools["Drivers"]["Tools"] }}/Extract-Certificate.ps1 -Source "vadrv/vaud_wdmx86.cat" -Output "vadrv.cer"'
        {% endif -%}
        - creates:
            - {{ pillar["Drivers"]["Audio"]["Path"] }}/vadrv.cer
        - require:
            - Install device finder tool on target
            - Install certificate extraction tool on target
            - Extract audio drivers on target

Trust audio driver certificate:
    cmd.run:
        - shell: powershell
        - cwd: {{ pillar["Drivers"]["Audio"]["Path"] }}
        - onlyif: '{{ pillar["Drivers"]["Tools"] }}/Find-Device.ps1 -Id "VAud_WDM"'
        - name: '{{ pillar["Drivers"]["Tools"] }}/Trust-Certificate.ps1 -Certificate "vadrv.cer"'
        - require:
            - Install device finder tool on target
            - Install certificate import tool on target
            - Extract certificate from audio driver

Install audio drivers using devcon:
    cmd.run:
        - shell: powershell
        - cwd: {{ pillar["Drivers"]["Audio"]["Path"] }}
        - onlyif: '{{ pillar["Drivers"]["Tools"] }}/Find-Device.ps1 -Id "VAud_WDM"'
        {% if grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" -%}
        - name: 'bin/devcon-64.exe install vadrv/VAud_WDM.inf VAud_WDM'
        {% else -%}
        - name: 'bin/devcon-32.exe install vadrv/VAud_WDM.inf VAud_WDM'
        {% endif -%}
        - require:
            - Install device finder tool on target
            - Trust audio driver certificate
            - Extract audio drivers on target
