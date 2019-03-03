include:
    - windows-services

## Manually download and install any updates required to use the
## Windows Update system.

# Download each update
{% for file in pillar["Updates"]["Agent"] -%}
Download Windows Update Agent -- {{ file.name }}:
    file.managed:
        - name: {{ salt["environ.get"]("TEMP") }}\{{ file.name }}
        - source: {{ file.source }}
        - source_hash: {{ file.hash }}

{% endfor -%}

# Install each update
{% for file in pillar["Updates"]["Agent"] -%}
Install Windows Update Agent -- {{ file.name }}:
    cmd.run:
        - name: {{ salt["environ.get"]("TEMP") }}\{{ file.name }} /quiet
        - cwd: {{ salt["environ.get"]("TEMP") }}
        - require:
            - Download Windows Update Agent -- {{ file.name }}
{% endfor -%}

# If there was a Windows Update Agent that was specified, then the following
# state collects all of the states that update it into a single state.
{% if pillar["Updates"]["Agent"] -%}
Installed all manual updates:
    test.succeed_with_changes:
        - name: test.succeed_with_changes
        {% if pillar["Updates"]["Agent"] -%}
        - require:
            {% for file in pillar["Updates"]["Agent"] -%}
            - Install Windows Update Agent -- {{ file.name }}
            {% endfor %}
        {%- endif %}

# If there was no need to update the Windows Update Agent, then the following
# state simulates that nothing happened
{% else -%}
Installed all manual updates:
    test.succeed_without_changes:
        - name: test.succeed_without_changes
{%- endif %}

Validate that the Windows Update Agent is of the correct version:
    event.send:
        - name: salt/minion/{{ grains["id"] }}/log
        - unless: 'if ( [System.Version]( Get-ItemProperty -Path ($env:windir + "/System32/wuaueng.dll")).VersionInfo.ProductVersion -ge [System.Version]"7.6.7600.256" ) { Exit 0 } else { Exit 1 }'
        - data:
            level: info
            message: "The Windows Update Agent is older than the required version."
        - require:
            - Installed all manual updates

    test.fail_without_changes:
        - name: test.fail_without_changes
        - unless: 'if ( [System.Version]( Get-ItemProperty -Path ($env:windir + "/System32/wuaueng.dll")).VersionInfo.ProductVersion -ge [System.Version]"7.6.7600.256" ) { Exit 0 } else { Exit 1 }'
        - require:
            - Installed all manual updates

## Begin the update cycle. The following states will continue
## downloading, updates, applying them, and restarting until there
## are no more available.

Download Windows Updates:
    module.run:
        - name: win_wua.list
        - download: true
        - skip_installed: true
        {% if pillar["Updates"]["Categories"] -%}
        - categories:
            {% for cat in pillar["Updates"]["Categories"] -%}
            - {{ cat }}
            {% endfor %}
        {% endif -%}
        - require:
            - Installed all manual updates

Install Windows Updates:
    module.run:
        - name: win_wua.list
        - download: false
        - install: true
        - skip_installed: true
        {% if pillar["Updates"]["Categories"] -%}
        - categories:
            {% for cat in pillar["Updates"]["Categories"] -%}
            - {{ cat }}
            {% endfor %}
        {% endif -%}
        - require:
            - Download Windows Updates

Everything is up to date:
    wua.uptodate:
        - software: true
        - drivers: true
        - skip_reboot: false
        {% if pillar["Updates"]["Categories"] -%}
        - categories:
            {% for cat in pillar["Updates"]["Categories"] -%}
            - {{ cat }}
            {% endfor %}
        {% endif -%}
        - require:
            - Install Windows Updates

## Rebooting the machine after success or failure
Reboot after updates:
    event.send:
        - name: salt/minion/{{ grains["id"] }}/log
        - data:
            level: info
            message: "Rebooting due to updates"
        - onchanges:
            - Everything is up to date
            - Installed all manual updates

    system.reboot:
        - message: Rebooting due to updates
        - timeout: 0
        - only_on_pending_reboot: true
        - onchanges:
            - Everything is up to date
            - Installed all manual updates

Reboot after failure:
    event.send:
        - name: salt/minion/{{ grains["id"] }}/log
        - data:
            level: info
            message: "Rebooting due to a failure while updating"
        - onfail:
            - Validate that the Windows update Agent is of the correct version
            - Everything is up to date

    system.reboot:
        - message: Rebooting due to updates
        - timeout: 0
        - only_on_pending_reboot: false
        - onfail:
            - Validate that the Windows update Agent is of the correct version
            - Everything is up to date

## Final reboot if any updates are pending
Reboot if necessary:
    system.reboot:
        - message: Reboot to satisfy pending changes
        - timeout: 0
        - only_on_pending_reboot: true
        - require:
            - Disable Microsoft's Windows Defender
            - Everything is up to date
