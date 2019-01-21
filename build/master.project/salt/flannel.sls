{% set FlannelService = pillar['service']['flannel'] %}

include:
    - etcd

## systemctl enable the flanneld.service
Enable systemd multi-user.target wants flanneld.service:
    file.symlink:
        - name: /etc/systemd/system/multi-user.target.wants/flanneld.service
        - target: /usr/lib/systemd/system/flanneld.service
        - makedirs: true

## etcd configuration
Register the flannel namespace:
    etcd.set:
        - name: {{ FlannelService.Namespace }}
        - value: null
        - directory: true
        - profile: root_etcd
        - requires:
            - sls: etcd

Register the network configuration for flannel:
    etcd.set:
        - name: {{ FlannelService.Namespace }}/config
        - value: {{ FlannelService.Configuration | json | yaml_dquote }}
        - profile: root_etcd
        - requires:
            - Register the flannel namespace
