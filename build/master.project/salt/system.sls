{% set Root = pillar["local"]["root"] %}

### Prerequisites required for any system units
Fetch the open-vm-tools image:
    cmd.run:
        - name: >-
            /usr/bin/ssh
            -i "{{ Root }}{{ pillar["toolbox"]["self-service"]["key"] }}"
            -o StrictHostKeyChecking=no
            -o UserKnownHostsFile=/dev/null
            --
            {{ pillar["toolbox"]["self-service"]["host"] | yaml_squote }}
            sudo
            --
            /bin/rkt
            fetch
            --insecure-options=image
            '{{ pillar["container"]["vmtoolsd"]["image"] }}:{{ pillar["container"]["vmtoolsd"]["version"] }}'
            >| '{{ Root }}{{ pillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["vmtoolsd"]["name"] }}:{{ pillar["container"]["vmtoolsd"]["version"] }}.id'

        - creates: '{{ Root }}{{ pillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["vmtoolsd"]["name"] }}:{{ pillar["container"]["vmtoolsd"]["version"] }}.id'

### Dropins for the different units
Make dropin directory for swap.service:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/var-swap-default.service.d
        - mode: 0755
        - makedirs: true

Make dropin directory for vmtoolsd.service:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/vmtoolsd.service.d
        - mode: 0755
        - makedirs: true

### Dropins for the different units
Set the default swap size:
    file.managed:
        - name: {{ Root }}/etc/systemd/system/var-swap-default.service.d/00-defaults.conf
        - mode: 0644
        - contents: |
            [Unit]
            ConditionPathExists=!/var/swap/{{ pillar["system"]["swap"]["name"] }}

            [Service]
            Environment="Name={{ pillar["system"]["swap"]["name"] }}"
            Environment="Size={{ pillar["system"]["swap"]["size"] }}"
        - require:
            - Make dropin directory for swap.service

Update swap.service dependency:
    file.managed:
        - name: {{ Root }}/etc/systemd/system/swap.service.d/50-var-swap-default.conf
        - mode: 0644
        - contents: |
            [Unit]
            Requires=var-swap-default.service
            ConditionPathExists=/var/swap/{{ pillar["system"]["swap"]["name"] }}
        - require:
            - Set the default swap size

Set the runtime environment for vmtoolsd.service:
    file.managed:
        - name: {{ Root }}/etc/systemd/system/vmtoolsd.service.d/50-environment.conf
        - mode: 0644
        - contents: |
            [Service]
            Environment="VMTOOLS_IMAGE={{ pillar["container"]["vmtoolsd"]["image"] }}"
            Environment="VMTOOLS_IMAGE_TAG={{ pillar["container"]["vmtoolsd"]["version"] }}"

            Environment="VMTOOLS_IMAGE_ID={{ pillar["container"]["vmtoolsd"]["uuid"] }}"
        - require:
            - Make dropin directory for vmtoolsd.service
            - Fetch the open-vm-tools image

### Systemd installation
Enable systemd multi-user.target wants swap.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/swap.service
        - target: /etc/systemd/system/swap.service
        - makedirs: true
        - require:
            - Update swap.service dependency

Enable systemd multi-user.target wants vmtoolsd.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/vmtoolsd.service
        - target: /etc/systemd/system/vmtoolsd.service
        - makedirs: true
        - require:
            - Set the runtime environment for vmtoolsd.service
