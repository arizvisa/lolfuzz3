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

Make bootstrap reactor directory:
    file.directory:
        - name: /srv/bootstrap/reactor
        - require:
            - Make service directory
        - use:
            - Make salt-master reactor directory

## salt reactor states
Install minion-pillar reaction:
    file.managed:
        - template: jinja
        - source: salt://reactor/minion-pillar.state
        - name: /srv/bootstrap/reactor/minion-pillar.sls
        - context:
            pillar_namespace: {{ pillar['configuration']['salt']['namespace'] }}/pillar
        - use:
            - Make bootstrap reactor directory
        - require:
            - Make bootstrap reactor directory

Install a salt-master reactor hightstate for creating the pillar for a minion:
    file.managed:
        - template: jinja
        - source: salt://reactor/default-top-state
        - name: /etc/salt/master.d/pillar.conf
        - context:
            reactor:
                - 'salt/minion/*/start':
                    - /srv/reactor/minion-pillar.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master configuration directory
            - Install minion-pillar reaction
        - makedirs: true

## salt reactor example states
Add salt-master reactor highstate into master configuration:
    file.symlink:
        - name: /etc/salt/master.d/reactor.conf
        - target: /srv/reactor/top.sls
        - require:
            - Install an example salt-master reactor highstate
            - Make salt-master configuration directory
        - makedirs: true

Install job-status.new reaction:
    file.managed:
        - source: salt://reactor/job-status-new.state
        - name: /srv/reactor/job-status.new.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory

Install job-status.ret reaction:
    file.managed:
        - source: salt://reactor/job-status-ret.state
        - name: /srv/reactor/job-status.ret.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory

Install run-status.new reaction:
    file.managed:
        - source: salt://reactor/run-status-new.state
        - name: /srv/reactor/run-status.new.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory

Install run-status.ret reaction:
    file.managed:
        - source: salt://reactor/run-status-ret.state
        - name: /srv/reactor/run-status.ret.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory

Install an example salt-master reactor highstate:
    file.managed:
        - template: jinja
        - source: salt://reactor/default-top-state
        - name: /srv/reactor/top.sls
        - context:
            reactor:
                - 'salt/job/*/new':
                    - /srv/reactor/job-status.new.sls

                - 'salt/job/*/ret':
                    - /srv/reactor/job-status.ret.sls

                - 'salt/run/*/new':
                    - /srv/reactor/run-status.new.sls

                - 'salt/run/*/ret':
                    - /srv/reactor/run-status.ret.sls
        - use:
            - Make salt-master reactor directory
        - require:
            - Make salt-master reactor directory
            - Install job-status.new reaction
            - Install job-status.ret reaction
            - Install run-status.new reaction
            - Install run-status.ret reaction
