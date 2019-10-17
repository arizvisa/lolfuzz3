{%- import_yaml "project-name.sls" as project_name -%}

# configuration for bootstrapping etcd and installation of salt
configuration:

    # project name and path
    name: {{ project_name | yaml_dquote }}
    path: 'git://path/to/{{ project_name }}/repository'

    # salt namespace
    salt: /coreos.com/salt

    # pillar namespace
    pillar: /lol/configuration
