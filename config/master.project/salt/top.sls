base:
    # All windows targets
    'G@os_family:Windows':
        - sync
        - id
        - windows

    # All linux targets
    'not G@os_family:Windows':
        - sync
        - id
        - linux

    # All targets
    '*':
        []
