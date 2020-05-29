base:
    # All masters
    'G@role:master':
        - identity
        - queue
        - store
        - fuzzer.deploy

    # All windows targets
    'G@os_family:Windows and not G@role:master':
        []

    # All linux targets
    'not G@os_family:Windows and not G@role:master':
        - updates

    # All targets
    'not G@role:master':
        - identity
        - audio
        - ramdisk
