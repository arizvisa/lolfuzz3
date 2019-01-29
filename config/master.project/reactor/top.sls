reactor:
    - 'salt/job/*/new':
        - /srv/reactor/job-status.new.sls

    - 'salt/job/*/ret':
        - /srv/reactor/job-status.ret.sls

    - 'salt/run/*/new':
        - /srv/reactor/run-status.new.sls

    - 'salt/run/*/ret':
        - /srv/reactor/run-status.ret.sls
