base:
    # All masters
    'G@role:master':
        - queue
        - store
        - fuzzer.deploy

    # All windows targets
    'G@os_family:Windows':
        - identity
        - audio
        - windows-services
        - windows-ramdisk

    # All linux targets
    'not G@os_family:Windows':
        - identity
        - audio
        - linux-updates

    # All targets
    '*':
        []
