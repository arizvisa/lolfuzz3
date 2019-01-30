Synchronize modules for the minion:
    module.run:
        - saltutil.sync_all:
            - refresh: true

Install required python-etcd module:
    pip.installed:
        - name: python-etcd
        - required:
            - Synchronize modules for the minion

Notify the master that we weren't able to install Python:
    event.send:
        - name: salt/minion/{{ grains['id'] }}/log
        - data:
            level: info
            message: "Unable to install Python onto {{ grains['id'] }}"
        - onfail:
            - Install required python-etcd module

Reboot after installing modules for salt-minion:
    event.send:
        - name: salt/minion/{{ grains['id'] }}/log
        - data:
            level: info
            message: "Rebooting {{ grains['id'] }} to refresh the Python modules used by the salt-minion service."
        - onchanges:
            - Install required python-etcd module

    system.reboot:
        - message: Rebooting to refresh salt-minion service
        - timeout: 0
        - only_on_pending_reboot: true
        - onchanges:
            - Install required python-etcd module
