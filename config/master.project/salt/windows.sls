Stop Microsoft's Windows Defender:
    service.stop:
        - name: WinDefend

Disable Microsoft's Windows Defender:
    service.disable:    
        - name: WinDefend
        - onchanges:
            - Stop Microsoft's Windows Defender

Download Windows Updates:
    module.run:
        - name: win_wua.list
        - download: true
        - skip_installed: true

Install Windows Updates:
    module.run:
        - name: win_wua.list
        - download: false
        - skip_installed: true
        - install: true
        - require:
            - Download Windows Updates

Everything is up to date:
    win_wua.uptodate:
        - software: true
        - drivers: true
        - skip_reboot: false
        - require:
            - Install Windows Updates

Reboot after updates:
    event.send:
        - name: salt/minion/{{ grains['id'] }}/log
        - data:
            level: info
            message: "Rebooting due to updates"
        - onchanges_any:
            - Everything is up to date

    system.reboot:
        - message: Rebooting due to updates
        - timeout: 0
        - only_on_pending_reboot: true
        - onchanges_any:
            - Everything is up to date

