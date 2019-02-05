base:
    # All windows targets
    'G@os_family:Windows':
        - sync
        - identity
        - windows-updates
        - windows-drivers
        - windows-audio
        - windows-ramdisk
        - windows-ramdisk-configuration

    # All linux targets
    'not G@os_family:Windows':
        - sync
        - identity
        - linux-updates

    # All targets
    '*':
        []
