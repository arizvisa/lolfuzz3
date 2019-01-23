
### container directory structure
Make container-root directory:
    file.directory:
        - name: {{ pillar['service']['container']['path'] }}
        - dir_mode: 1755
        - file_mode: 0664
        - makedirs: True

Make container-root build directory:
    file.directory:
        - name: {{ pillar['service']['container']['path'] }}/build
        - use:
            - Make container-root directory
        - require:
            - Make container-root directory
        - dir_mode: 1755
        - file_mode: 0664

Make container-root image directory:
    file.directory:
        - name: {{ pillar['service']['container']['path'] }}/image
        - use:
            - Make container-root directory
        - require:
            - Make container-root directory
        - dir_mode: 1755
        - file_mode: 0664

Make container-root tools directory:
    file.directory:
        - name: {{ pillar['service']['container']['path'] }}/tools
        - use:
            - Make container-root directory
        - require:
            - Make container-root directory
        - dir_mode: 0755
        - file_mode: 0664

### container tools (FIXME: either check the signature, or replace this with just an archive.extracted)
{% for item in pillar['service']['container']['tools'] %}
Transfer container-root tools ({{ item.Source }}):
    file.managed:
        - source: salt://files/{{ item.Source }}
        - source_hash: {{ item.Algo }}={{ item.Hash }}
        - name: {{ pillar['service']['container']['path'] }}/tools/{{ item.Source }}
        - require:
            - Make container-root tools directory
        - mode: 0640
{% endfor %}

Extract container-root tools:
    archive.extracted:
        - source: {{ pillar['service']['container']['path'] }}/tools/{{ pillar['service']['container']['tools'] | map(attribute='Source') | first }}
        - name: {{ pillar['service']['container']['path'] }}/tools
        - require:
        {% for item in pillar['service']['container']['tools'] %}
            - Transfer container-root tools ({{ item.Source }})
        {% endfor %}
        - user: root
        - group: root

### container-build service
Install container build script:
    file.managed:
        - source: salt://container/build.sh
        - name: {{ pillar['service']['container']['path'] }}/build.sh
        - require:
            - Make container-root directory
            - Extract container-root tools
        - mode: 0775

Install container-build.service script:
    file.managed:
        - source: salt://container/container-build.sh
        - name: {{ pillar['service']['container']['path'] }}/container-build.sh
        - use:
            - file: Install container build script
        - require:
            - Install container build script
            - Make container-root build directory
            - Make container-root image directory
        - mode: 0775

Install container-build.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-build.service
        - name: /etc/systemd/system/container-build.service
        - defaults:
            container_path: {{ pillar['service']['container']['path'] }}
        - require:
            - Install container-build.service script
        - mode: 0664

Install container-build.path:
    file.managed:
        - source: salt://container/container-build.path
        - name: /etc/systemd/system/container-build.path
        - use:
            - Install container-build.service
        - require:
            - Install container-build.service
        - mode: 0664

### container load service
Install container load script:
    file.managed:
        - source: salt://container/load.sh
        - name: {{ pillar['service']['container']['path'] }}/load.sh
        - require:
            - Make container-root directory
        - mode: 0775

Install container-load.service script:
    file.managed:
        - source: salt://container/container-load.sh
        - name: {{ pillar['service']['container']['path'] }}/container-load.sh
        - use:
            - Install container load script
        - require:
            - Make container-root image directory
            - Install container load script
        - mode: 0775

Install container-load.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-load.service
        - name: /etc/systemd/system/container-load.service
        - defaults:
            container_path: {{ pillar['service']['container']['path'] }}
        - require:
            - Install container-load.service script
        - mode: 0664

Install container-load.path:
    file.managed:
        - source: salt://container/container-load.path
        - name: /etc/systemd/system/container-load.path
        - use:
            - Install container-load.service
        - require:
            - Install container-load.service
        - mode: 0664

### container update service
Install container update script:
    file.managed:
        - source: salt://container/update.sh
        - name: {{ pillar['service']['container']['path'] }}/update.sh
        - require:
            - Make container-root directory
            - Make container-root image directory
        - mode: 0775

Install container-sync.service script:
    file.managed:
        - source: salt://container/container-update.sh
        - name: {{ pillar['service']['container']['path'] }}/container-update.sh
        - use:
            - Install container update script
        - require:
            - Make container-root image directory
            - Install container update script
        - mode: 0775

Install container-sync.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-sync.service
        - name: /etc/systemd/system/container-sync.service
        - defaults:
            container_path: {{ pillar['service']['container']['path'] }}
        - require:
            - Install container-sync.service script
        - mode: 0664

Install container-sync.path:
    file.managed:
        - source: salt://container/container-sync.path
        - name: /etc/systemd/system/container-sync.path
        - use:
            - Install container-sync.service
        - require:
            - Install container-sync.service
        - mode: 0664

### symbolic links for all services
# container-build
Enable systemd multi-user.target wants container-build.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-build.path
        - target: /etc/systemd/system/container-build.path
        - require:
            - Install container-build.path
        - makedirs: true

Enable systemd container-build.path requires container-build.service:
    file.symlink:
        - name: /etc/systemd/system/container-build.path.requires/container-build.service
        - target: /etc/systemd/system/container-build.service
        - require:
            - Install container-build.service
        - makedirs: true

# container-load
Enable systemd multi-user.target wants container-load.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-load.path
        - target: /etc/systemd/system/container-load.path
        - require:
            - Install container-load.path
        - makedirs: true

Enable systemd container-load.path requires container-load.service:
    file.symlink:
        - name: /etc/systemd/system/container-load.path.requires/container-load.service
        - target: /etc/systemd/system/container-load.service
        - require:
            - Install container-load.service
        - makedirs: true

# container-sync
Enable systemd multi-user.target wants container-sync.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-sync.path
        - target: /etc/systemd/system/container-sync.path
        - require:
            - Install container-sync.path
        - makedirs: true

Enable systemd multi-user.target wants container-sync.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-sync.service
        - target: /etc/systemd/system/container-sync.service
        - require:
            - Install container-sync.service
        - makedirs: true

Enable systemd container-sync.path requires container-sync.service:
    file.symlink:
        - name: /etc/systemd/system/container-sync.path.requires/container-sync.service
        - target: /etc/systemd/system/container-sync.service
        - require:
            - Install container-sync.service
        - makedirs: true
