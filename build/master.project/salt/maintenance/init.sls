{% set Root = pillar["local"]["root"] %}

Install rkt-gc.service:
    file.managed:
        - template: jinja
        - name: {{ Root }}/etc/systemd/system/rkt-gc.service
        - source: salt://maintenance/command.service
        - context:
            description: Run rkt-gc to clean up any exited pods
            command: /bin/rkt gc
        - mode: 0644

Install rkt-gc.timer:
    file.managed:
        - template: jinja
        - name: {{ Root }}/etc/systemd/system/rkt-gc.timer
        - source: salt://maintenance/command.timer
        - context:
            description: Run rkt-gc at a set interval
        - require:
            - Install rkt-gc.service
        - mode: 0644

Register rkt-gc.timer dropin directory:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/rkt-gc.timer.d
        - require:
            - Install rkt-gc.timer
        - mode: 0755

Install rkt-gc.timer interval dropin:
    file.managed:
        - template: jinja
        - name: {{ Root }}/etc/systemd/system/rkt-gc.timer.d/50-interval.conf
        - source: salt://maintenance/timer.dropin
        - context:
            timer:
                OnCalendar: '*:00/30'
        - require:
            - Register rkt-gc.timer dropin directory
        - mode: 0644

Enable systemd multi-user.target wants rkt-gc.timer:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/rkt-gc.timer
        - target: /etc/systemd/system/rkt-gc.timer
        - require:
            - Install rkt-gc.timer
            - Install rkt-gc.timer interval dropin
        - makedirs: true
