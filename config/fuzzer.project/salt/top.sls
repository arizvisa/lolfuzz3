base:
    # All masters
    'G@role:master':
        - queue
        - store
        - fuzzer

    # All windows targets
    'G@os_family:Windows':
        - identity
        - windows-services
        - windows-audio
        - windows-ramdisk
        - windows-updates

    # All linux targets
    'not G@os_family:Windows':
        - identity
        - linux-updates

    # All targets
    '*':
        []
