reactor:

    # Receive a log from a minion
    - 'salt/minion/*/log':
        - /srv/reactor/minion-log.sls
