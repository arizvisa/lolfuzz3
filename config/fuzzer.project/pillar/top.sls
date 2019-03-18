# Master environment
master:
    'G@role:master':
        - store
        - queue

# Base environment
base:
    # All windows targets
    'G@os_family:Windows':
        - windows-drivers
        - windows-updates

    # All linux targets
    'not G@os_family:Windows':
        []

    # All targets
    '*':
        []
