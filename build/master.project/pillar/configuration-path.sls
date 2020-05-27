# configuration for bootstrapping etcd and installation of salt

configuration:

    # lol namespace and base pillar for entire project
    base: /lol

    # salt namespace for returner and cache
    salt: /coreos.com/salt

    # salt pillar base for individual minionss
    minion: /lol/minion

