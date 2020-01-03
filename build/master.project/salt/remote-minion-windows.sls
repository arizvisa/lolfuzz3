{% set Root = pillar["local"]["root"] %}
{% set Config = salt["config.get"]("conf_file") %}
{% set ConfigDir = Config.rsplit("/" if Config.startswith("/") else "\\", 1)[0] %}
{% set PythonVersion = salt["grains.get"]("pythonversion") | join('.') %}

include:
    - remote-minion-common

## Bootstrap the chocolatey package manager
Bootstrap an installation of the chocolatey package manager:
    module.run:
        - chocolatey.bootstrap:
            []
        - require_in:
            - Install all required Python Modules

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
            - Install all required Python Modules
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
            - Install all required Python Modules
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
            - Install required Python module -- pywin32
            - Install required Python module -- pythonnet
            - Install required Python module -- pycurl
            - Install all required Python Modules

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
            - sls: remote-minion-common
            - Re-install minion configuration
            - Update the Windows Service (salt-minion) to be able to interact with the desktop

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
