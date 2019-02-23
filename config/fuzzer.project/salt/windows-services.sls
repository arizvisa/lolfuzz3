## Services
Disable Microsoft's Windows Defender:
    service.disabled:
        - name: WinDefend

Stop Microsoft's Windows Defender:
    service.dead:
        - name: WinDefend
        - onchanges:
            - Disable Microsoft's Windows Defender


