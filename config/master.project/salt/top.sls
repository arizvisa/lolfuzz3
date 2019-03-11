base:
    # All windows targets
    'G@os_family:Windows':
        - identity
        - windows

    # All linux targets
    'not G@os_family:Windows':
        - identity
        - linux

    # All targets
    '*':
        []
