base:
    # All windows targets
    'G@os_family:Windows':
        - id
        - windows

    # All linux targets
    'not G@os_family:Windows':
        - id
        - linux

    # All targets
    '*':
        []
