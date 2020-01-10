{% set Root = pillar["local"]["root"] %}
{% set Config = salt["config.get"]("conf_file") %}
{% set ConfigDir = Config.rsplit("/" if Config.startswith("/") else "\\", 1)[0] %}
{% set PythonVersion = salt["grains.get"]("pythonversion") | join('.') %}

Upgrade required package -- pip:
    pip.installed:
        - name: pip
        - upgrade: true

## Bootstrap the chocolatey package manager
Bootstrap an installation of the chocolatey package manager:
    module.run:
        - chocolatey.bootstrap:
            []

## Install Microsoft's Visual C++ Runtime as required by Python
{% if PythonVersion.startswith("2") -%}
Install Visual C++ 9.0 Runtime for Python 2.x:
    chocolatey.installed:
        - name: vcpython27
        {% if grains["cpuarch"].lower() in ["x86"] -%}
        - force_x86: true
        {% else -%}
        - force_x86: false
        {% endif -%}
        - require:
            - Bootstrap an installation of the chocolatey package manager
        - require_in:
            - Install required Python module -- pywin32
            - Install required Python module -- pycurl
            - Install required Python module -- pythonnet
{% else -%}
Install Visual C++ 14.0 Runtime for Python 3.x:
    chocolatey.installed:
        - name: vcredist140
        {% if grains["cpuarch"].lower() in ["x86"] -%}
        - force_x86: true
        {% else -%}
        - force_x86: false
        {% endif -%}
        - require:
            - Bootstrap an installation of the chocolatey package manager
        - require_in:
            - Install required Python module -- pywin32
            - Install required Python module -- pycurl
            - Install required Python module -- pythonnet
{% endif -%}

## Install the binary packages required by Salt
Install required Python module -- pywin32:
    pip.installed:
        - name: pywin32
        - use_wheel: true
        - require:
            - Upgrade required package -- pip

Install required Python module -- pycurl:
    pip.installed:
        - name: pycurl >= 7.43.0.2
        - use_wheel: true
        - require:
            - Upgrade required package -- pip

Install required Python module -- pythonnet:
    pip.installed:
        - name: pythonnet >= 2.3.0
        - use_wheel: true
        - require:
            - Upgrade required package -- pip

Install all required Python modules:
    pip.installed:
        - requirements: salt://config/requirements.txt
        - reload_modules: true
        - ignore_installed: true
        - require:
            - Upgrade required package -- pip
            - Install required Python module -- pywin32
            - Install required Python module -- pythonnet
            - Install required Python module -- pycurl

### Module fixes required to work with the cluster
Synchronize all modules for the minion:
    module.run:
        - func: saltutil.sync_all
        - kwargs:
            saltenv: bootstrap
        - require:
            - Install all required Python modules

Deploy the salt.utils.templates module directly into the remote-minion's site-packages:
    file.managed:
        - name: {{ grains["saltpath"] }}/utils/templates.py
        - source: salt://_utils/templates.py
        - require:
            - Install all required Python modules

Deploy the salt.utils.path module directly into the remote-minion's site-packages:
    file.managed:
        - name: {{ grains["saltpath"] }}/utils/path.py
        - source: salt://_utils/path.py
        - require:
            - Install all required Python modules

## Install the new minion configuration (and service configuration)
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
            - Synchronize all modules for the minion
            - Deploy the salt.utils.templates module directly into the remote-minion's site-packages
            - Deploy the salt.utils.path module directly into the remote-minion's site-packages

Create minion configuration directory:
    file.directory:
        - name: '{{ ConfigDir }}/minion.d'
        - require:
            - Install all required Python modules

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
                path_prefix: '{{ pillar["project"]["salt"] }}/cache'
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
                returner_root: '{{ pillar["project"]["salt"] }}/return'

        - require:
            - Create minion configuration directory
            - Synchronize all modules for the minion

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

## Restart the minion into the new cluster
Restart minion with new configuration:
    module.run:
        - system.reboot:
            - timeout: 1
        - require:
            - Upgrade required package -- pip
            - Install required Python module -- pywin32
            - Install required Python module -- pythonnet
            - Install required Python module -- pycurl
            - Update the Windows Service (salt-minion) to be able to interact with the desktop
            - Re-install minion configuration
            - Install minion common configuration
            - Install minion etcd configuration

Restart minion on failure:
    module.run:
        - system.reboot:
            - timeout: 1
        - require:
            - Upgrade required package -- pip
            - Install required Python module -- pywin32
            - Install required Python module -- pythonnet
            - Install required Python module -- pycurl
        - onfail:
            - Install all required Python modules
