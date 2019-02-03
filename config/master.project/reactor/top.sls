reactor:

    # Job creation and result logging
    - 'salt/job/*/new':
        - /srv/reactor/logging/job-status.new.sls

    - 'salt/job/*/ret/*':
        - /srv/reactor/logging/job-status.ret.sls

    # Job (runner) creation and result logging
    - 'salt/run/*/new':
        - /srv/reactor/logging/run-status.new.sls

    - 'salt/run/*/ret':
        - /srv/reactor/logging/run-status.ret.sls

    # Receive a log from a minion
    - 'salt/minion/*/log':
        - /srv/reactor/minion-log.sls
