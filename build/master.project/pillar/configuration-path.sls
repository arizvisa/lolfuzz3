# configuration for bootstrapping etcd and installation of salt

configuration:

    # lol namespace
    base: /lol

    # salt namespace for returner and cache
    salt: /coreos.com/salt

    # salt pillar base for entire project
    pillar: /lol/base

    # salt pillar base for individual minionss
    minion: /lol/minion

