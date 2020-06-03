{% set Root = pillar["local"]["root"] %}

Install the lol-toolbox wrapper:
    file.managed:
        - template: jinja
        - source: salt://container/toolbox.command
        - name: /opt/sbin/lol-toolbox

        - defaults:
            toolbox: /bin/toolbox

        - context:
            mounts:
                - /sys
                - /var/run/dbus
                - /etc/systemd
                - /opt
                - /var/cache/salt
                - /var/run/salt
                - /var/log/salt
                - {{ pillar["service"]["container"]["paths"]["image"] }}
                - {{ pillar["service"]["container"]["paths"]["run"] }}
                - /srv

        - mode: 0755
        - makedirs: true
        - require:
            - Make container image directory
            - Make container run directory

### oci containers
Install some tools for dealing with OCI containers into the toolbox:
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
            /opt/sbin/lol-toolbox
            dnf -y install buildah skopeo

        - require:
            - Install the lol-toolbox wrapper
            - Make container image directory
            - Make container run directory

### container directory structure
Make container build directory:
    file.directory:
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["build"] }}'
        - makedirs: true
        - dir_mode: 1755
        - file_mode: 0664

Make container image directory:
    file.directory:
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["image"] }}'
        - makedirs: true
        - dir_mode: 0755
        - file_mode: 0664

Make container run directory:
    file.directory:
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["run"] }}'
        - makedirs: true
        - dir_mode: 0755
        - file_mode: 0664

Make container tools directory:
    file.directory:
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["tools"] }}'
        - makedirs: true
        - dir_mode: 0755
        - file_mode: 0664

Make container service-tools directory:
    file.directory:
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["service-tools"] }}'
        - makedirs: true
        - dir_mode: 0755
        - file_mode: 0664

### container tools
Create temporary directory for container tools:
    file.directory:
        - name: '{{ Root }}{{ pillar["toolbox"]["self-service"]["temporary"] }}'
        - makedirs: true

{% for item in pillar["service"]["container"]["tools"] %}
Transfer container tools ({{ item.Source }}):
    file.managed:
        - source: 'salt://files/{{ item.Source }}'
        - source_hash: '{{ item.Algo }}={{ item.Hash }}'
        - name: '{{ Root }}{{ pillar["toolbox"]["self-service"]["temporary"] }}/{{ item.Source }}'
        - require:
            - Create temporary directory for container tools
        - mode: 0640
{% endfor %}

Create temporary tools-extraction directory:
    file.directory:
        - name: {{ pillar["service"]["container"]["tools-extract"]["temporary"] | yaml_dquote }}
        - makedirs: true

Extract container tools:
    archive.extracted:
        - source: '{{ Root }}{{ pillar["toolbox"]["self-service"]["temporary"] }}/{{ pillar["service"]["container"]["tools"] | map(attribute="Source") | first }}'
        - name: {{ pillar["service"]["container"]["tools-extract"]["temporary"] | yaml_dquote }}
        - require:
            - Create temporary tools-extraction directory
        {% for item in pillar["service"]["container"]["tools"] %}
            - Transfer container tools ({{ item.Source }})
        {% endfor %}
        - user: root
        - group: root

Deploy container tools:
    cmd.run:
        - name: 'mv -v {{ pillar["service"]["container"]["tools-extract"]["match"] }} "{{ Root }}{{ pillar["service"]["container"]["paths"]["tools"] }}"'
        - cwd: {{ pillar["service"]["container"]["tools-extract"]["temporary"] | yaml_dquote }}
        - require:
            - Install some tools for dealing with OCI containers into the toolbox
            - Extract container tools
            - Create temporary tools-extraction directory
            - Make container tools directory

### container-build service
Install container build script:
    file.managed:
        - source: salt://container/build.sh
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["service-tools"] }}/build.sh'
        - require:
            - Make container service-tools directory
            - Deploy container tools
        - mode: 0775

Install container-build.service script:
    file.managed:
        - source: salt://container/container-build.sh
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["service-tools"] }}/container-build.sh'
        - use:
            - file: Install container build script
        - require:
            - Install container build script
            - Make container build directory
            - Make container image directory
        - mode: 0775

Install container-build.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-build.service
        - name: {{ Root }}/etc/systemd/system/container-build.service
        - defaults:
            container_build_path: {{ pillar["service"]["container"]["paths"]["build"] | yaml_dquote }}
            container_image_path: {{ pillar["service"]["container"]["paths"]["image"] | yaml_dquote }}
            container_service_path: {{ pillar["service"]["container"]["paths"]["service-tools"] | yaml_dquote }}
        - require:
            - Install container-build.service script
        - mode: 0644

Install container-build.path:
    file.managed:
        - source: salt://container/container-build.path
        - name: {{ Root }}/etc/systemd/system/container-build.path
        - use:
            - Install container-build.service
        - require:
            - Install container-build.service
        - mode: 0644

### container load service
Install container load script:
    file.managed:
        - source: salt://container/load.sh
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["service-tools"] }}/load.sh'
        - require:
            - Make container service-tools directory
        - mode: 0775

Install container-load.service script:
    file.managed:
        - source: salt://container/container-load.sh
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["service-tools"] }}/container-load.sh'
        - use:
            - Install container load script
        - require:
            - Make container image directory
            - Install container load script
        - mode: 0775

Install container-load.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-load.service
        - name: {{ Root }}/etc/systemd/system/container-load.service
        - defaults:
            container_image_path: {{ pillar["service"]["container"]["paths"]["image"] | yaml_dquote }}
            container_service_path: {{ pillar["service"]["container"]["paths"]["service-tools"] | yaml_dquote }}
        - require:
            - Install container-load.service script
        - mode: 0644

Install container-load.path:
    file.managed:
        - source: salt://container/container-load.path
        - name: {{ Root }}/etc/systemd/system/container-load.path
        - use:
            - Install container-load.service
        - require:
            - Install container-load.service
        - mode: 0644

### container update service
Install container update script:
    file.managed:
        - source: salt://container/update.sh
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["service-tools"] }}/update.sh'
        - require:
            - Make container service-tools directory
            - Make container image directory
        - mode: 0775

Install container-sync.service script:
    file.managed:
        - source: salt://container/container-update.sh
        - name: '{{ Root }}{{ pillar["service"]["container"]["paths"]["service-tools"] }}/container-update.sh'
        - use:
            - Install container update script
        - require:
            - Make container image directory
            - Install container update script
        - mode: 0775

Install container-sync.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-sync.service
        - name: {{ Root }}/etc/systemd/system/container-sync.service
        - defaults:
            container_image_path: {{ pillar["service"]["container"]["paths"]["image"] | yaml_dquote }}
            container_service_path: {{ pillar["service"]["container"]["paths"]["service-tools"] | yaml_dquote }}
        - require:
            - Install container-sync.service script
        - mode: 0644

Install container-sync.path:
    file.managed:
        - source: salt://container/container-sync.path
        - name: {{ Root }}/etc/systemd/system/container-sync.path
        - use:
            - Install container-sync.service
        - require:
            - Install container-sync.service
        - mode: 0644

### symbolic links for all services
# container-build
Enable systemd multi-user.target wants container-build.path:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/container-build.path
        - target: /etc/systemd/system/container-build.path
        - require:
            - Install container-build.path
        - makedirs: true

Enable systemd container-build.path requires container-build.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/container-build.path.requires/container-build.service
        - target: /etc/systemd/system/container-build.service
        - require:
            - Install container-build.service
        - makedirs: true

# container-load
Enable systemd multi-user.target wants container-load.path:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/container-load.path
        - target: /etc/systemd/system/container-load.path
        - require:
            - Install container-load.path
        - makedirs: true

Enable systemd container-load.path requires container-load.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/container-load.path.requires/container-load.service
        - target: /etc/systemd/system/container-load.service
        - require:
            - Install container-load.service
        - makedirs: true

# container-sync
Enable systemd multi-user.target wants container-sync.path:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/container-sync.path
        - target: /etc/systemd/system/container-sync.path
        - require:
            - Install container-sync.path
        - makedirs: true

Enable systemd multi-user.target wants container-sync.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/multi-user.target.wants/container-sync.service
        - target: /etc/systemd/system/container-sync.service
        - require:
            - Install container-sync.service
        - makedirs: true

Enable systemd container-sync.path requires container-sync.service:
    file.symlink:
        - name: {{ Root }}/etc/systemd/system/container-sync.path.requires/container-sync.service
        - target: /etc/systemd/system/container-sync.service
        - require:
            - Install container-sync.service
        - makedirs: true
