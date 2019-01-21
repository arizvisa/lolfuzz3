include:
    - stack
    - master

## salt reactor configuration
Make salt-master reactor directory:
    file.directory:
        - name: /srv/reactor
        - require:
            - Make service directory
        - use:
            - Make service directory
        - mode: 1775

Install a default salt-master reactor highstate:
    file.managed:
        - template: jinja
        - source: salt://reactor/default.top-state
        - name: /srv/reactor/top.sls
        - defaults:
            reactor:
                'salt/minion/*/start':
                    - /srv/reactor/minion-status.sls
                'salt/job/*/new':
                    - /srv/reactor/job-status.new.sls
                'salt/job/*/ret/*':
                    - /srv/reactor/job-status.ret.sls
                'salt/run/*/new':
                    - /srv/reactor/run-status.new.sls
                'salt/run/*/ret':
                    - /srv/reactor/run-status.ret.sls
        - use:
            - Make salt-master reactor directory
        - requires:
            - Make salt-master reactor directory

Add salt-master reactor highstate into master configuration:
    file.symlink:
        - name: /etc/salt/master.d/reactor.conf
        - target: /srv/reactor/top.sls
        - require:
            - Install a default salt-master reactor highstate
            - Make salt-master configuration directory
        - makedirs: true

## salt reactor states
Install reactor minion-status state:
    file.managed:
        - template: jinja
        - source: salt://reactor/minion.status-state
        - name: /srv/reactor/minion-status.sls
        - defaults:
            path: {{ pillar['service']['salt-master']['Namespace'] }}
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory

Install reactor job-status.new state:
    file.managed:
        - source: salt://reactor/job-status.new-state
        - name: /srv/reactor/job-status.new.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory

Install reactor job-status.ret state:
    file.managed:
        - source: salt://reactor/job-status.ret-state
        - name: /srv/reactor/job-status.ret.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory

Install reactor run-status.new state:
    file.managed:
        - source: salt://reactor/run-status.new-state
        - name: /srv/reactor/run-status.new.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory

Install reactor run-status.ret state:
    file.managed:
        - source: salt://reactor/run-status.ret-state
        - name: /srv/reactor/run-status.ret.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory
