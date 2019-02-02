{%- import_yaml '../project-name.sls' as project_name -%}

# configuration for bootstrapping etcd and installation of salt
configuration:

    # project name
    project: {{ project_name }}
    repository: "git://path/to/{{ project_name }}/repository"

    # salt namespace
    salt: "/coreos.com/salt"
