base:
    # All windows targets
    'G@os_family:Windows':
        - id
        - python
        - windows

    # All linux targets
    'G@os_family:RedHat or G@os_family:Suse or G@os_family:Debian or G@os_family:Slackware or G@os_family:Mandriva or G@os_family:Gentoo or G@os_family:Arch':
        - id
        - python
        - linux

    # All targets
    '*':
        []
