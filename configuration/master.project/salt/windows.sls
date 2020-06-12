## Services
Disable Microsoft's Windows Defender:
    service.disabled:
        - name: WinDefend

Stop Microsoft's Windows Defender:
    service.dead:
        - name: WinDefend
        - onchanges:
            - Disable Microsoft's Windows Defender

## Updates
Download Windows Updates:
    module.run:
        - win_wua.list:
            - download: true
            - skip_installed: true

Install Windows Updates:
    module.run:
        - win_wua.list:
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

## Rebooting after changes
Reboot after updates:
    event.send:
        - name: salt/minion/{{ grains['id'] }}/log
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
        - name: salt/minion/{{ grains['id'] }}/log
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

## Final reboot if it is pending
Reboot if necessary:
    system.reboot:
        - message: Reboot to satisfy pending changes
        - timeout: 0
        - only_on_pending_reboot: true
        - require:
            - Disable Microsoft's Windows Defender
            - Everything is up to date
