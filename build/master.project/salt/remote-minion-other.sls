{% set Root = pillar["local"]["root"] %}
{% set Config = salt["config.get"]("conf_file") %}
{% set ConfigDir = Config.rsplit("/" if Config.startswith("/") else "\\", 1)[0] %}
{% set PythonVersion = salt["grains.get"]("pythonversion") | join('.') %}
{% set PythonSuffix = "2" if PythonVersion.startswith("2") else "3" %}

include:
    - remote-minion-common

## Python development headers + libraries
Install required package -- python-devel:
    pkg.installed:
        {% if grains["os_family"] in ["RedHat", "FreeBSD", "NetBSD", "OpenBSD"] -%}
        - name: python-devel
        {% elif grains["os_family"] in ["Debian", "Suse"] -%}
        - name: python-dev
        {% elif grains["os_family"] in ["Arch"] -%}
        - name: python
        {% else -%}
        - name: {{ raise("Unsupported os family {}".format(grains["os_family"])) }}
        {%- endif %}

Install required package -- pythonX-devel:
    pkg.installed:
        {% if grains["os_family"] in ["RedHat", "FreeBSD", "NetBSD", "OpenBSD"] -%}
        - name: python{{ PythonSuffix }}-devel
        {% elif grains["os_family"] in ["Debian", "Suse"] -%}
        - name: python{{ PythonSuffix }}-dev
        {% elif grains["os_family"] in ["Arch"] -%}
        - name: python{{ PythonSuffix }}
        {% else -%}
        - name: {{ raise("Unsupported os family {}".format(grains["os_family"])) }}
        {% endif -%}
        - onfail:
            - Install required package -- python-devel

Try installation of package -- python-devel:
    test.succeed_with_changes:
        - name: Try and install python-devel using package manager
        - require_any:
            - Install required package -- python-devel
            - Install required package -- pythonX-devel
        - require_in:
            - sls: remote-minion-common

## Python package installer (pip)
Install required package -- python-pip:
    pkg.installed:
        - name: python-pip

Install required package -- pythonX-pip:
    pkg.installed:
        - name: python{{ PythonSuffix }}-pip
        - onfail:
            - Install required package -- python-pip

Try installation of package -- pip:
    test.succeed_with_changes:
        - name: Try and install pip using package manager
        - require:
            - Try installation of package -- python-devel
        - require_any:
            - Install required package -- python-pip
            - Install required package -- pythonX-pip
        - require_in:
            - sls: remote-minion-common

## Python libcurl bindings
Install required package -- pycurl:
    pkg.installed:
        - name: pycurl

Install required package -- python-pycurl:
    pkg.installed:
        - name: python-pycurl
        - onfail:
            - Install required package -- pycurl

Install required package -- pythonX-pycurl:
    pkg.installed:
        - name: python{{ PythonSuffix }}-pycurl
        - onfail:
            - Install required package -- python-pycurl

Try installation of package -- pycurl:
    test.succeed_with_changes:
        - name: Try and install pycurl using package manager
        - require_any:
            - Install required package -- pycurl
            - Install required package -- python-pycurl
            - Install required package -- pythonX-pycurl
        - require_in:
            - sls: remote-minion-common

## Lock in the minion configuration
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
                ipc_mode: ipc
                root_dir: {{ Root | yaml_dquote }}
                startup_states: highstate
                saltenv: base
                pillarenv: base

        - require:
            - sls: remote-minion-common
            - Try installation of package -- python-devel
            - Try installation of package -- pip
            - Try installation of package -- pycurl
        - mode: 0664

## Retry on success or failure
Restart minion with new configuration:
    module.run:
        - service.restart:
            - name: salt-minion
            - no_block: true
        - require:
            - sls: remote-minion-common
            - Re-install minion configuration

Restart minion on failure:
    module.run:
        - service.restart:
            - name: salt-minion
            - no_block: true
        - onfail:
            - Install all required Python modules
