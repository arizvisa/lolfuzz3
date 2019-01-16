### symbolic link for service
Enable systemd multi-user.target wants flanneld.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/flanneld.service
        - target: /usr/lib/systemd/system/flanneld.service
        - makedirs: true

