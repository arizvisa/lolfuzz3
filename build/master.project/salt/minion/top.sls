bootstrap:

    # Windows minions that need to be re-provisioned
    'G@os_family:Windows':
        - remote-minion-config
        - remote-minion-windows

    # Other minions that need to be re-provisioned
    'not G@os_family:Windows':
        - remote-minion-config
        - remote-minion-other
