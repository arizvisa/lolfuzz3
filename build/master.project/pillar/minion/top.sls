bootstrap:
    # any minions that are running Windows
    'G@os_family:Windows':
        - minion-windows

    # any minions that are running Linux
    'not G@os_family:Windows':
        - minion-linux
