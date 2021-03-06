# Base environment
base:
    # All masters
    'G@role:master':
        - queue
        - store
        - fuzzer

    # All windows targets
    'G@os_family:Windows':
        - windows
        - updates

    # All linux targets
    'not G@os_family:Windows':
        []

    # All targets
    'not G@role:master':
        - audio
        - ramdisk
