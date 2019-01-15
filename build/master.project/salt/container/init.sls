{% set container = pillar['master']['service']['container'] %}

### container directory structure
Make container-root directory:
    file.directory:
        - name: {{ container['path'] }}
        - dir_mode: 0755
        - file_mode: 0664
        - makedirs: True
Make container-root build directory:
    file.directory:
        - name: {{ container['path'] }}/build
        - use:
            - file: Make container-root directory
        - require:
            - file: Make container-root directory
        - dir_mode: 0755
        - file_mode: 0664
Make container-root image directory:
    file.directory:
        - name: {{ container['path'] }}/image
        - use:
            - file: Make container-root directory
        - require:
            - file: Make container-root directory
        - dir_mode: 0755
        - file_mode: 0664
Make container-root tools directory:
    file.directory:
        - name: {{ container['path'] }}/tools
        - use:
            - file: Make container-root directory
        - require:
            - file: Make container-root directory
        - dir_mode: 0755
        - file_mode: 0664

### container tools (FIXME: either check the signature, or replace this with just an archive.extracted)
{% for item in container['acbuild'] %}
Transfer container-root tools ({{item.source}}):
    file.managed:
        - source: salt://files/{{ item.source }}
        - source_hash: {{ item.algo }}={{ item.hash }}
        - name: {{ container['path'] }}/tools/{{ item.source }}
        - require:
            - file: Make container-root tools directory
        - mode: 0640
{% endfor %}
Extract container-root tools:
    archive.extracted:
        - source: {{ container['path'] }}/tools/{{ container['acbuild'] | map(attribute='source') | first }}
        - name: {{ container['path'] }}/tools
        - require:
        {% for item in container['acbuild'] %}
            - file: Transfer container-root tools ({{item.source}})
        {% endfor %}
        - user: root
        - group: root

### container-build service
Install container build script:
    file.managed:
        - source: salt://container/build.sh
        - name: {{ container['path'] }}/build.sh
        - require:
            - file: Make container-root directory
            - archive: Extract container-root tools
        - mode: 0775
Install container-build.service script:
    file.managed:
        - source: salt://container/container-build.sh
        - name: {{ container['path'] }}/container-build.sh
        - use:
            - file: Install container build script
        - require:
            - file: Install container build script
            - file: Make container-root build directory
            - file: Make container-root image directory
        - mode: 0775
Install container-build.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-build.service
        - name: /etc/systemd/system/container-build.service
        - defaults:
            container_path: {{ container['path'] }}
        - require:
            - file: Install container-build.service script
        - mode: 0664
Install container-build.path:
    file.managed:
        - source: salt://container/container-build.path
        - name: /etc/systemd/system/container-build.path
        - use:
            - file: Install container-build.service
        - require:
            - file: Install container-build.service
        - mode: 0664

### container load service
Install container load script:
    file.managed:
        - source: salt://container/load.sh
        - name: {{ container['path'] }}/load.sh
        - require:
            - file: Make container-root directory
        - mode: 0775
Install container-load.service script:
    file.managed:
        - source: salt://container/container-load.sh
        - name: {{ container['path'] }}/container-load.sh
        - use:
            - file: Install container load script
        - require:
            - file: Make container-root image directory
            - file: Install container load script
        - mode: 0775
Install container-load.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-load.service
        - name: /etc/systemd/system/container-load.service
        - defaults:
            container_path: {{ container['path'] }}
        - require:
            - file: Install container-load.service script
        - mode: 0664
Install container-load.path:
    file.managed:
        - source: salt://container/container-load.path
        - name: /etc/systemd/system/container-load.path
        - use:
            - file: Install container-load.service
        - require:
            - file: Install container-load.service
        - mode: 0664

### container update service
Install container update script:
    file.managed:
        - source: salt://container/update.sh
        - name: {{ container['path'] }}/update.sh
        - require:
            - file: Make container-root directory
            - file: Make container-root image directory
        - mode: 0775
Install container-sync.service script:
    file.managed:
        - source: salt://container/container-update.sh
        - name: {{ container['path'] }}/container-update.sh
        - use:
            - file: Install container update script
        - require:
            - file: Make container-root image directory
            - file: Install container update script
        - mode: 0775
Install container-sync.service:
    file.managed:
        - template: jinja
        - source: salt://container/container-sync.service
        - name: /etc/systemd/system/container-sync.service
        - defaults:
            container_path: {{ container['path'] }}
        - require:
            - file: Install container-sync.service script
        - mode: 0664
Install container-sync.path:
    file.managed:
        - source: salt://container/container-sync.path
        - name: /etc/systemd/system/container-sync.path
        - use:
            - file: Install container-sync.service
        - require:
            - file: Install container-sync.service
        - mode: 0664

### symbolic links for all services
# container-build
Enable systemd multi-user.target wants container-build.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-build.path
        - target: /etc/systemd/system/container-build.path
        - require:
            - file: Install container-build.path
        - makedirs: true
Enable systemd container-build.path requires container-build.service:
    file.symlink:
        - name: /etc/systemd/system/container-build.path.requires/container-build.service
        - target: /etc/systemd/system/container-build.service
        - require:
            - file: Install container-build.service
        - makedirs: true

# container-load
Enable systemd multi-user.target wants container-load.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-load.path
        - target: /etc/systemd/system/container-load.path
        - require:
            - file: Install container-load.path
        - makedirs: true
Enable systemd container-load.path requires container-load.service:
    file.symlink:
        - name: /etc/systemd/system/container-load.path.requires/container-load.service
        - target: /etc/systemd/system/container-load.service
        - require:
            - file: Install container-load.service
        - makedirs: true

# container-sync
Enable systemd multi-user.target wants container-sync.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-sync.path
        - target: /etc/systemd/system/container-sync.path
        - require:
            - file: Install container-sync.path
        - makedirs: true
Enable systemd multi-user.target wants container-sync.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-sync.service
        - target: /etc/systemd/system/container-sync.service
        - require:
            - file: Install container-sync.service
        - makedirs: true
Enable systemd container-sync.path requires container-sync.service:
    file.symlink:
        - name: /etc/systemd/system/container-sync.path.requires/container-sync.service
        - target: /etc/systemd/system/container-sync.service
        - require:
            - file: Install container-sync.service
        - makedirs: true

### Enable all services (note: these are dead because we're just updating the symbolic links, not actually starting anything.)
#container-build.service:
#    service.dead:
#        - enable: true
#container-build.path:
#    service.dead:
#        - enable: true
#container-load.service:
#    service.dead:
#        - enable: true
#container-load.path:
#    service.dead:
#        - enable: true
#container-sync.path:
#    service.dead:
#        - enable: true
#container-sync.service:
#    service.dead:
#        - enable: true
