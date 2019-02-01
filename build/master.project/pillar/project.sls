{%- import_yaml 'project-name.sls' as project_name -%}

# configuration for bootstrapping etcd and installation of salt
configuration:

    # project name
    project: {{ project_name }}

    # service configurations
    salt:
        namespace: "/coreos.com/salt"

    # project namespace configuration
    defaults:
        repository: "git://path/to/{{ project_name }}/repository"
        project: {{ project_name }}
        service: {}
        template: {}
        pod: {}

    # default cluster size and discovery url when seeding the etcd cluster
    etcd:
        discovery: "/coreos.com/discovery"
        cluster-size: 1

    # configuration for any extra scripts/tools
    tools:
        prefix: /opt
