base:
    # All windows targets
    'G@os_family:Windows':
        - identity
        - windows-updates
        - windows-drivers
        - windows-audio
        - windows-ramdisk

    # All linux targets
    'not G@os_family:Windows':
        - identity
        - linux-updates

    # All targets
    '*':
        []
