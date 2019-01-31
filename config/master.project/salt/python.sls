Synchronize modules for the minion:
    module.run:
        - saltutil.sync_all:
            - refresh: true

Install required python-etcd module:
    pip.installed:
        - name: python-etcd
        - reload_modules: true
        - required:
            - Synchronize modules for the minion

Notify the master that we weren't able to install Python dependencies:
    event.send:
        - name: salt/minion/{{ grains['id'] }}/log
        - data:
            level: info
            message: "Unable to install Python dependencies onto {{ grains['id'] }}"
        - onfail_any:
            - Install required python-etcd module
            - Synchronize modules for the minion
