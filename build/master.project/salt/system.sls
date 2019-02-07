{% set Root = pillar["local"]["root"] %}

### Dropins for the different swap units
Make dropin directory for swap.service:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/var-swap-default.service.d
        - mode: 0755
        - makedirs: true

### Swap file size
Set the default swap size:
    file.managed:
        - name: {{ Root }}/etc/systemd/system/var-swap-default.service.d/00-defaults.conf
        - mode: 0644
        - contents: |
            [Service]
            ConditionPathExists=!/var/swap/{{ pillar["system"]["swap"]["name"] }}
            Environment="Name={{ pillar["system"]["swap"]["name"] }}"
            Environment="Size={{ pillar["system"]["swap"]["size"] }}"
        - require:
            - Make dropin directory for swap.service

### Update dependency
Update swap.service dependency:
    file.managed:
        - name: {{ Root }}/etc/systemd/system/swap.service.d/50-var-swap-default.conf
        - mode: 0644
        - contents: |
            [Service]
            ConditionPathExists=/var/swap/{{ pillar["system"]["swap"]["name"] }}
            Requires=var-swap-default.service
        - require:
            - Set the default swap size

### Systemd installation
Enable systemd multi-user.target wants swap.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/swap.service
        - target: /etc/systemd/system/swap.service
        - makedirs: true
        - require:
            - Update swap.service dependency
