# Base environment
base:
    # All windows targets
    'G@os_family:Windows':
        []

    # All linux targets
    'not G@os_family:Windows':
        []

    # All targets
    '*':
        []

    # Development
    'G@role:dev':
        - drivers
