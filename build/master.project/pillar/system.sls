# configuration of system services
system:
    swap:
        name: default
        size: 4096m

container:
    vmtoolsd:
        name: open-vm-tools
        image: docker://linuxkit/open-vm-tools
        version: v0.8
        uuid: /var/lib/coreos/vmtoolsd.uuid
