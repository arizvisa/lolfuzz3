{% set Root = pillar["local"]["root"] %}

Ensure that git-daemon.service exists:
    file.exists:
        - name: {{ Root }}/etc/systemd/system/git-daemon.service

Install a default gitignore file:
    file.managed:
        - name: {{ Root }}/srv/.gitignore
        - replace: false
        - contents: |
            /bootstrap/*
        - mode: 0644

Enable systemd multi-user.target wants git-daemon.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/git-daemon.service
        - target: /etc/systemd/system/git-daemon.service
        - require:
            - Ensure that git-daemon.service exists
            - Install a default gitignore file
        - makedirs: true

