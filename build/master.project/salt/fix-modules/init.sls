include:
    - master

Make returners external modules directory:
    file.directory:
        - name: /srv/salt/_returners
        - require:
            - Make salt-master files directory
        - mode: 0775

Fix the etcd_return.py module:
    file.managed:
        - source: salt://fix-modules/etcd_return.py
        - name: /srv/salt/_returners/etcd_return.py
        - require:
            - Make returners external modules directory
        - mode: 0664
