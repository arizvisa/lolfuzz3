{%- import_yaml "project-name.sls" as project_name -%}

# configuration for bootstrapping etcd and installation of salt
configuration:

    # project name and path
    name: {{ project_name | yaml_dquote }}
    path: 'git://path/to/{{ project_name }}/repository'

    # lol namespace
    base: /lol

    # salt namespace for returner + cache
    salt: /coreos.com/salt

    # salt pillar base for entire project
    pillar: /lol/base

    # salt pillar base for individual minionss
    minion: /lol/minion
