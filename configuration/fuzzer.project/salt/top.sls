base:
    # All masters
    'G@role:master':
        - queue
        - store
        - fuzzer.deploy

    # All windows targets
    'G@os_family:Windows':
        - identity
        - identity.windows-services
        - audio
        - ramdisk

    # All linux targets
    'not G@os_family:Windows':
        - identity
        - audio
        - ramdisk
        - linux-updates

    # All targets
    '*':
        []
