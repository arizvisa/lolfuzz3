{% set Root = pillar["local"]["root"] %}

### Dropins for the different swap units
Make dropin directory for swap.service:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/swap.service.d
        - mode: 0755
        - makedirs: true

### Swap file size
Set the default swap size:
    file.managed:
        - name: {{ Root }}/etc/systemd/system/swap.service.d/00-defaults.conf
        - mode: 0644
        - contents: |
            [Service]
            Environment="Size={{ pillar["service"]["system"]["swap"] }}"
        - require:
            - Make dropin directory for swap.service

### Systemd installation
Enable systemd multi-user.target wants var-swap-default.swap:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/var-swap-default.swap
        - target: /etc/systemd/system/var-swap-default.swap
        - makedirs: true
        - require:
            - Set the default swap size
