Install rkt-gc service:
    file.managed:
        - template: jinja
        - name: /etc/systemd/system/rkt-gc.service
        - source: salt://maintenance/command.service
        - context:
            description: Run rkt-gc to clean up any exited pods
            command: /bin/rkt gc
        - mode: 0664

Install rkt-gc service timer:
    file.managed:
        - template: jinja
        - name: /etc/systemd/system/rkt-gc.timer
        - source: salt://maintenance/command.timer
        - context:
            description: Run rkt-gc at a set interval
        - require:
            - Install rkt-gc service
        - mode: 0664

Register rkt-gc timer dropin directory:
    file.directory:
        - name: /etc/systemd/system/rkt-gc.timer.d
        - require:
            - Install rkt-gc service timer
        - mode: 0775

Install rkt-gc service timer dropin:
    file.managed:
        - template: jinja
        - name: /etc/systemd/system/rkt-gc.timer.d/50-interval.conf
        - source: salt://maintenance/timer.dropin
        - context:
            timer:
                OnCalendar: '*:00/30'
        - require:
            - Register rkt-gc timer dropin directory
        - mode: 0664

Enable systemd multi-user.target wants rkt-gc.timer:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/rkt-gc.timer
        - target: /etc/systemd/system/rkt-gc.timer
        - require:
            - Install rkt-gc service timer
            - Install rkt-gc service timer dropin
        - makedirs: true
