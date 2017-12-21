{% set container = pillar['master']['service']['container'] %}

### container directory structure
Make container-root directory:
    file.directory:
        - name: {{ container['path'] }}
        - user: root
        - group: root
        - dir_mode: 755
        - file_mode: 644
        - makedirs: True
Make container-root build directory:
    file.directory:
        - name: {{ container['path'] }}/build
        - use:
            - file: Make container-root directory
        - require:
            - file: Make container-root directory
Make container-root image directory:
    file.directory:
        - name: {{ container['path'] }}/image
        - use:
            - file: Make container-root directory
        - require:
            - file: Make container-root directory
Make container-root tools directory:
    file.directory:
        - name: {{ container['path'] }}/tools
        - use:
            - file: Make container-root directory
        - require:
            - file: Make container-root directory

### container tools (FIXME: either check the signature, or replace this with just an archive.extracted)
{% for item in container['acbuild'] %}
Transfer container-root tools ({{item.source}}):
    file.managed:
        - source: salt://files/{{ item.source }}
        - name: {{ container['path'] }}/tools/{{ item.source }}
        - source_hash: {{ item.algo }}={{ item.hash }}
        - mode: 0640
        - require:
            - file: Make container-root tools directory
{% endfor %}
Extract container-root tools:
    archive.extracted:
        - source: {{ container['path'] }}/tools/{{ container['acbuild'] | map(attribute='source') | first }}
        - name: {{ container['path'] }}/tools
        - user: root
        - group: root
        - require:
        {% for item in container['acbuild'] %}
            - file: Transfer container-root tools ({{item.source}})
        {% endfor %}

### container-build service
Install container build script:
    file.managed:
        - source: salt://container/build.sh
        - name: {{ container['path'] }}/build.sh
        - user: root
        - group: root
        - mode: 0775
        - require:
            - file: Make container-root directory
            - archive: Extract container-root tools
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
Install container-build.service:
    file.managed:
        - source: salt://container/container-build.service
        - name: /etc/systemd/system/container-build.service
        - user: root
        - group: root
        - template: jinja
        - defaults:
            container_path: {{ container['path'] }}
        - require:
            - file: Install container-build.service script
Install container-build.path:
    file.managed:
        - source: salt://container/container-build.path
        - name: /etc/systemd/system/container-build.path
        - use:
            - file: Install container-build.service
        - require:
            - file: Install container-build.service

### container load service
Install container load script:
    file.managed:
        - source: salt://container/load.sh
        - name: {{ container['path'] }}/load.sh
        - user: root
        - group: root
        - mode: 0775
        - require:
            - file: Make container-root directory
Install container-load.service script:
    file.managed:
        - source: salt://container/container-load.sh
        - name: {{ container['path'] }}/container-load.sh
        - use:
            - file: Install container load script
        - require:
            - file: Make container-root image directory
            - file: Install container load script
Install container-load.service:
    file.managed:
        - source: salt://container/container-load.service
        - name: /etc/systemd/system/container-load.service
        - user: root
        - group: root
        - template: jinja
        - defaults:
            container_path: {{ container['path'] }}
        - require:
            - file: Install container-load.service script
Install container-load.path:
    file.managed:
        - source: salt://container/container-load.path
        - name: /etc/systemd/system/container-load.path
        - use:
            - file: Install container-load.service
        - require:
            - file: Install container-load.service

### container update service
Install container update script:
    file.managed:
        - source: salt://container/update.sh
        - name: {{ container['path'] }}/update.sh
        - user: root
        - group: root
        - mode: 0775
        - require:
            - file: Make container-root directory
            - file: Make container-root image directory
Install container-sync.service script:
    file.managed:
        - source: salt://container/container-update.sh
        - name: {{ container['path'] }}/container-update.sh
        - use:
            - file: Install container update script
        - require:
            - file: Make container-root image directory
            - file: Install container update script
Install container-sync.service:
    file.managed:
        - source: salt://container/container-sync.service
        - name: /etc/systemd/system/container-sync.service
        - user: root
        - group: root
        - template: jinja
        - defaults:
            container_path: {{ container['path'] }}
        - require:
            - file: Install container-sync.service script
Install container-sync.path:
    file.managed:
        - source: salt://container/container-sync.path
        - name: /etc/systemd/system/container-sync.path
        - use:
            - file: Install container-sync.service
        - require:
            - file: Install container-sync.service

### symbolic links for all services
# container-build
Enable systemd multi-user.target wants container-build.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-build.path
        - target: /etc/systemd/system/container-build.path
        - makedirs: true
        - require:
            - file: Install container-build.path
Enable systemd container-build.path requires container-build.service:
    file.symlink:
        - name: /etc/systemd/system/container-build.path.requires/container-build.service
        - target: /etc/systemd/system/container-build.service
        - makedirs: true
        - require:
            - file: Install container-build.service

# container-load
Enable systemd multi-user.target wants container-load.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-load.path
        - target: /etc/systemd/system/container-load.path
        - makedirs: true
        - require:
            - file: Install container-load.path
Enable systemd container-load.path requires container-load.service:
    file.symlink:
        - name: /etc/systemd/system/container-load.path.requires/container-load.service
        - target: /etc/systemd/system/container-load.service
        - makedirs: true
        - require:
            - file: Install container-load.service

# container-sync
Enable systemd multi-user.target wants container-sync.path:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-sync.path
        - target: /etc/systemd/system/container-sync.path
        - makedirs: true
        - require:
            - file: Install container-sync.path
Enable systemd multi-user.target wants container-sync.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/container-sync.service
        - target: /etc/systemd/system/container-sync.service
        - makedirs: true
        - require:
            - file: Install container-sync.service
Enable systemd container-sync.path requires container-sync.service:
    file.symlink:
        - name: /etc/systemd/system/container-sync.path.requires/container-sync.service
        - target: /etc/systemd/system/container-sync.service
        - makedirs: true
        - require:
            - file: Install container-sync.service

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
