## Manually download and install any updates required to use the
## Windows Update system.

# Download each update
{% for file in pillar["Updates"] -%}
Download Windows Update -- {{ file.name }}:
    file.managed:
        - name: {{ salt["environ.get"]("TEMP") }}\{{ file.name }}
        - source: {{ file.source }}
        - source_hash: {{ file.hash }}

{% endfor -%}

# Install each update
{% for file in pillar["Updates"] -%}
Install Windows Update -- {{ file.name }}:
    cmd.run:
        - name: {{ salt["environ.get"]("TEMP") }}\{{ file.name }} /quiet /norestart
        - cwd: {{ salt["environ.get"]("TEMP") }}
        - require:
            - Download Windows Update -- {{ file.name }}
{% endfor -%}

Install all manual updates (dummy state):
    test.succeed_with_changes:
        - name: test.succeed_with_changes

## Begin the update cycle. The following states will continue
## downloading, updates, applying them, and restarting until there
## are no more available.

Download Windows Updates:
    module.run:
        - name: win_wua.list
        - download: true
        - skip_installed: true
        - require:
            - Install all manual updates (dummy state)
            {% for file in pillar["Updates"] -%}
            - Install Windows Update -- {{ file.name }}
            {% endfor %}

Install Windows Updates:
    module.run:
        - name: win_wua.list
        - download: false
        - skip_installed: true
        - install: true
        - require:
            - Download Windows Updates

Everything is up to date:
    wua.uptodate:
        - software: true
        - drivers: true
        - skip_reboot: false
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

    system.reboot:
        - message: Rebooting due to updates
        - timeout: 0
        - only_on_pending_reboot: true
        - onchanges:
            - Everything is up to date

Reboot after failure:
    event.send:
        - name: salt/minion/{{ grains["id"] }}/log
        - data:
            level: info
            message: "Rebooting due to a failure while updating"
        - onfail:
            - Everything is up to date

    system.reboot:
        - message: Rebooting due to updates
        - timeout: 0
        - only_on_pending_reboot: false
        - onfail:
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
