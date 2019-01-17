# configuration for flannel bridge which facilitates communicaton between containers

master:
    service:
        flannel:
            Namespace: "/coreos.com/network"
            Configuration:
                Network: 10.1.0.0/16
                SubnetLen: 28
                SubnetMin: 10.1.10.0
                SubnetMax: 10.1.50.0

