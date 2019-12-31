include:
    - identity.drivers

Make audio driver path:
    file.directory:
        - name: {{ pillar["Drivers"]["Audio"]["Path"] }}
        - makedirs: true
        - require:
            - Create the base driver directory

Extract audio drivers on target:
    archive.extracted:
        - name: {{ pillar["Drivers"]["Audio"]["Path"] }}
        - source: salt://audio/vadrv.zip
        - archive_format: zip
        - enforce_toplevel: false
        - require:
            - Make audio driver path

Extract certificate from audio driver:
    cmd.run:
        - shell: powershell
        - cwd: {{ pillar["Drivers"]["Audio"]["Path"] }}
        {% if grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" -%}
        - name: '{{ pillar["Drivers"]["Tools"] }}/Extract-Certificate.ps1 -Source "{{ pillar["Drivers"]["Audio"]["Path"] }}/vadrv/vaud_wdmx64.cat" -Output "{{ pillar["Drivers"]["Audio"]["Path"] }}/vadrv.cer"'
        - unless: 'if (( & "bin/devcon-64.exe" status VAud_WDM) -like "*Driver is running.*") { Exit 0 } else { Exit 1 }'
        {% else -%}
        - name: '{{ pillar["Drivers"]["Tools"] }}/Extract-Certificate.ps1 -Source "{{ pillar["Drivers"]["Audio"]["Path"] }}/vadrv/vaud_wdmx86.cat" -Output "{{ pillar["Drivers"]["Audio"]["Path"] }}/vadrv.cer"'
        - unless: 'if (( & "bin/devcon-32.exe" status VAud_WDM) -like "*Driver is running.*") { Exit 0 } else { Exit 1 }'
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
        {% if grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" -%}
        - unless: 'if (( & "bin/devcon-64.exe" status VAud_WDM) -like "*Driver is running.*") { Exit 0 } else { Exit 1 }'
        {% else -%}
        - unless: 'if (( & "bin/devcon-32.exe" status VAud_WDM) -like "*Driver is running.*") { Exit 0 } else { Exit 1 }'
        {% endif -%}
        - name: '{{ pillar["Drivers"]["Tools"] }}/Trust-Certificate.ps1 -Certificate "{{ pillar["Drivers"]["Audio"]["Path"] }}/vadrv.cer"'
        - require:
            - Install device finder tool on target
            - Install certificate import tool on target
            - Extract certificate from audio driver

Install audio drivers using devcon:
    cmd.run:
        - shell: powershell
        - cwd: {{ pillar["Drivers"]["Audio"]["Path"] }}
        {% if grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" -%}
        - name: 'bin/devcon-64.exe install vadrv/VAud_WDM.inf VAud_WDM'
        - unless: 'if (( & "bin/devcon-64.exe" status VAud_WDM) -like "*Driver is running.*") { Exit 0 } else { Exit 1 }'
        {% else -%}
        - name: 'bin/devcon-32.exe install vadrv/VAud_WDM.inf VAud_WDM'
        - unless: 'if (( & "bin/devcon-32.exe" status VAud_WDM) -like "*Driver is running.*") { Exit 0 } else { Exit 1 }'
        {% endif -%}
        - require:
            - Install device finder tool on target
            - Trust audio driver certificate
            - Extract audio drivers on target
