master:
    # configuration for project services
    service:
        # flannel bridge for communication between containers
        flannel:
            Namespace: "/coreos.com/network"
            Network: 10.1.0.0/16
            SubnetLen: 28
            SubnetMin: 10.1.10.0
            SubnetMax: 10.1.50.0

