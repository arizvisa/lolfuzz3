{% set Root = pillar["local"]["root"] %}
{% set ConfigDir = salt["config.get"]("config_dir") %}

## Add exclusions to Windows Defender for Salt and other things
Add the salt-minion path to the exclusions for Windows Defender:
    {% if grains["osrelease"] in ("7", "8") -%}
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths
        - vname: {{ grains["saltpath"].split("\\", 2)[:-1] | join("\\") | yaml_dquote }}
        - vtype: REG_DWORD
        - vdata: 0x00000000
    {% else -%}
    cmd.run:
        - name: Add-MpPreference -ExclusionPath "{{ grains["saltpath"].split("\\", 2)[:-1] | join("\\") }}"
        - shell: powershell
    {% endif %}

Add the salt-minion process to the exclusions for Windows Defender:
    {% if grains["osrelease"] in ("7", "8") -%}
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes
        - vname: salt-minion.exe
        - vtype: REG_DWORD
        - vdata: 0x00000000
    {% else -%}
    cmd.run:
        - name: Add-MpPreference -ExclusionProcess "salt-minion.exe"
        - shell: powershell
    {% endif %}

Add the python path to the exclusions for Windows Defender:
    {% if grains["osrelease"] in ("7", "8") -%}
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths
        - vname: C:\Python37
        - vtype: REG_DWORD
        - vdata: 0x00000000
    {% else -%}
    cmd.run:
        - name: Add-MpPreference -ExclusionPath "C:\Python37"
        - shell: powershell
    {% endif %}

Add the python process to the exclusions for Windows Defender:
    {% if grains["osrelease"] in ("7", "8") -%}
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions\Processes
        - vname: python.exe
        - vtype: REG_DWORD
        - vdata: 0x00000000
    {% else -%}
    cmd.run:
        - name: Add-MpPreference -ExclusionProcess "python.exe"
        - shell: powershell
    {% endif %}

Add exclusions for Windows Defender:
    test.succeed_without_changes:
        - require:
            - Add the salt-minion path to the exclusions for Windows Defender
            - Add the salt-minion process to the exclusions for Windows Defender
            - Add the python path to the exclusions for Windows Defender
            - Add the python process to the exclusions for Windows Defender

## Ensure the the Windows Update Service (wuauserv) is enabled and running
## so that chocolatey can install windows components unhindered

Ensure the Windows Update service is running:
    service.running:
        - name: wuauserv
        - enable: true

### Module fixes required to work with the cluster
Synchronize all modules for the minion:
    saltutil.sync_all:
        - refresh: true
        - saltenv: bootstrap
        - require:
            - Add exclusions for Windows Defender

{% if grains["saltversioninfo"][0] | int < 3000 -%}
Deploy the salt.utils.templates module directly into the remote-minion's site-packages:
    file.managed:
        - name: {{ grains["saltpath"] }}/utils/templates.py
        - source: salt://_utils/templates.py
        - require:
            - Synchronize all modules for the minion

Deploy the salt.utils.path module directly into the remote-minion's site-packages:
    file.managed:
        - name: {{ grains["saltpath"] }}/utils/path.py
        - source: salt://_utils/path.py
        - require:
            - Synchronize all modules for the minion
{% endif -%}

## Bootstrap chocolatey and install external version of Python
Bootstrap an installation of the chocolatey package manager:
    module.run:
        - chocolatey.bootstrap:
            []
        - require:
            - Ensure the Windows Update service is running
            - Synchronize all modules for the minion

Install chocolatey package -- Python 3.7:
    chocolatey.installed:
        - name: python
        - version: '3.7.7'
        {% if grains["cpuarch"].lower() in ["x86"] -%}
        - force_x86: true
        {% else -%}
        - force_x86: false
        {% endif -%}
        - require:
            - Add exclusions for Windows Defender
            - Bootstrap an installation of the chocolatey package manager

Upgrade required package -- pip:
    pip.installed:
        - name: pip
        - upgrade: true
        - bin_env: C:\Python37\Scripts\pip.exe
        - require:
            - Install chocolatey package -- Python 3.7

Install required Python module -- wheel:
    pip.installed:
        - name: wheel
        - bin_env: C:\Python37\Scripts\pip.exe
        - require:
            - Upgrade required package -- pip

## Install the binary packages required by Salt
Install required Python module -- pywin32:
    pip.installed:
        - name: 'pywin32 == 227'
        - bin_env: C:\Python37\Scripts\pip.exe
        - require:
            - Install required Python module -- wheel

Install required Python module -- pycurl:
    pip.installed:
        - name: pycurl
        - bin_env: C:\Python37\Scripts\pip.exe
        - require:
            - Install required Python module -- wheel

Install required Python module -- WMI:
    pip.installed:
        - name: 'WMI == 1.4.9'
        - bin_env: C:\Python37\Scripts\pip.exe
        - require:
            - Install required Python module -- wheel

Install required Python module -- pythonnet:
    pip.installed:
        - name: 'pythonnet == 2.4.0'
        - bin_env: C:\Python37\Scripts\pip.exe
        - require:
            - Install required Python module -- wheel

Install all required Python modules:
    pip.installed:
        - requirements: salt://config/requirements.txt
        - reload_modules: true
        - ignore_installed: true
        - bin_env: C:\Python37\Scripts\pip.exe
        - require:
            - Upgrade required package -- pip
            - Install required Python module -- wheel
            - Install required Python module -- pywin32
            - Install required Python module -- WMI
            - Install required Python module -- pythonnet
            - Install required Python module -- pycurl

Install required Python module -- salt:
    pip.installed:
        - name: 'salt == {{ grains["saltversion"] }}'
        - bin_env: C:\Python37\Scripts\pip.exe
        - no_deps: true
        - require:
            - Install all required Python modules

## Install the new minion configuration (and service configuration)
Create minion configuration directory:
    file.directory:
        - name: '{{ ConfigDir }}/minion.d'
        - require:
            - Install all required Python modules
            - Install required Python module -- salt

Install minion common configuration:
    file.managed:
        - template: jinja
        - name: '{{ ConfigDir }}/minion.d/common.conf'
        - source: salt://config/common.conf
        - defaults:
            ipv6: false
            transport: zeromq
        - require:
            - Create minion configuration directory

Install minion etcd configuration:
    file.managed:
        - template: jinja
        - name: '{{ ConfigDir }}/minion.d/etcd.conf'
        - source: salt://config/etcd.conf
        - defaults:
            etcd_cache:
                host: {{ opts["master"] | yaml_dquote }}
                port: 2379
                path_prefix: '{{ pillar["configuration"]["salt"] }}/cache'
                allow_reconnect: true
                allow_redirect: true

            etcd_hosts:
                - name: root_etcd
                  host: {{ opts["master"] | yaml_dquote }}
                  port: 2379

                - name: minion_etcd
                  host: {{ opts["master"] | yaml_dquote }}
                  port: 2379

            etcd_returner:
                returner: root_etcd
                returner_root: '{{ pillar["configuration"]["salt"] }}/return'

        - require:
            - Create minion configuration directory
            - Synchronize all modules for the minion

Re-install minion configuration:
    file.managed:
        - template: jinja
        - name: '{{ ConfigDir }}/minion'
        - source: salt://config/custom.conf
        - defaults:
            configuration:
                master: {{ grains["master"] | yaml_dquote }}
                log_level: warning
                hash_type: sha256
                id: {{ grains["id"] | yaml_dquote }}
                ipc_mode: tcp
                root_dir: {{ Root | yaml_dquote }}
                startup_states: highstate
                saltenv: base
                pillarenv: base

        - require:
            - Upgrade required package -- pip
            - Install all required Python Modules
            - Install required Python module -- salt
            - Synchronize all modules for the minion
            {% if grains["saltversioninfo"][0] | int < 3000 -%}
            - Deploy the salt.utils.templates module directly into the remote-minion's site-packages
            - Deploy the salt.utils.path module directly into the remote-minion's site-packages
            {% endif -%}
            - Install minion common configuration
            - Install minion etcd configuration

# There's no binary arithmetic or negation in Jinja, so we hack/cheat by
# checking if the ServiceType is larger than the flag we want, if it
# isn't, then we'll add ServiceType_InteractiveProcess(0x100) in an
# attempt to actually set the flag

# No hex in Jinja, because people are fucking stupid.
{% set ServiceType_KernelDriver         = 1 %}
{% set ServiceType_FileSystemDriver     = 2 %}
{% set ServiceType_Adapter              = 4 %}
{% set ServiceType_RecognizerDriver     = 8 %}
{% set ServiceType_Win32OwnProcess      = 16 %}
{% set ServiceType_Win32ShareProcess    = 32 %}
{% set ServiceType_InteractiveProcess   = 256 %}

{% set Minion_ServiceType = salt["reg.read_value"]("HKEY_LOCAL_MACHINE", "SYSTEM\\CurrentControlSet\\services\\salt-minion", "Type")["vdata"] | default(0, true) %}

Update the Windows Service (salt-minion) to be able to interact with the desktop:
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\salt-minion
        - vname: Type
        - vdata: {{ Minion_ServiceType if Minion_ServiceType >= ServiceType_InteractiveProcess else Minion_ServiceType + ServiceType_InteractiveProcess }}
        - vtype: REG_DWORD

Update the Windows Service (salt-minion) to use external Python interpreter:
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\salt-minion\Parameters
        - vname: Application
        - vdata: C:\Python37\Scripts\salt-minion.exe
        - vtype: REG_EXPAND_SZ
        - require:
            - Add exclusions for Windows Defender
            - Install chocolatey package -- Python 3.7
            - Upgrade required package -- pip
            - Install required Python module -- pywin32
            - Install required Python module -- WMI
            - Install required Python module -- pycurl
            - Install required Python module -- pythonnet
            - Install all required Python modules
            - Install required Python module -- salt

Update the Windows Service (salt-minion) to use external Python interpreter parameters:
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\salt-minion\Parameters
        - vname: AppParameters
        - vdata: '-l info -c "{{ ConfigDir }}"'
        - vtype: REG_EXPAND_SZ
        - require:
            - Add exclusions for Windows Defender
            - Install chocolatey package -- Python 3.7
            - Upgrade required package -- pip
            - Install required Python module -- pywin32
            - Install required Python module -- WMI
            - Install required Python module -- pycurl
            - Install required Python module -- pythonnet
            - Install all required Python modules
            - Install required Python module -- salt

## Restart the minion into the new cluster
Restart minion with new configuration:
    module.run:
        - system.reboot:
            - timeout: 1
        - require:
            - Update the Windows Service (salt-minion) to use external Python interpreter
            - Update the Windows Service (salt-minion) to use external Python interpreter parameters
            - Update the Windows Service (salt-minion) to be able to interact with the desktop
            - Re-install minion configuration

Restart minion on failure:
    module.run:
        - system.reboot:
            - timeout: 0
        - require:
            - Bootstrap an installation of the chocolatey package manager
        - onfail_any:
            - Install chocolatey package -- Python 3.7
            - Upgrade required package -- pip
            - Install required Python module -- pywin32
            - Install required Python module -- WMI
            - Install required Python module -- pycurl
            - Install required Python module -- pythonnet
            - Install all required Python modules
            - Install required Python module -- salt
            - Synchronize all modules for the minion
