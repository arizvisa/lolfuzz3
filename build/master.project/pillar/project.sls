{%- import_yaml 'project-name.sls' as project_name -%}

# configuration for bootstrapping etcd and installation of salt
configuration:

    # project name
    project: {{ project_name }}
    repository: "git://path/to/{{ project_name }}/repository"

    # service configurations
    salt:
        namespace: "/coreos.com/salt"
