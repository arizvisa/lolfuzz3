{%- import_yaml 'project-name.sls' as project_name -%}

# configuration for bootstrapping etcd and installation of salt
configuration:

    # project name
    project: {{ project_name }}

    # project namespace configuration
    defaults:
        repository: "git://path/to/{{ project_name }}/repository"
        project: {{ project_name }}
        service: {}
        template: {}
        pod: {}

    # path to root filesystem while running CoreOS' toolbox
    root: /media/root

    # how the toolbox authenticates back to the host
    remote:
        host: core@localhost
        key: /home/core/.ssh/id_rsa

    # default cluster size when seeding the etcd master
    etcd:
        cluster-size: 3

    # configuration for any extra scripts/tools
    tools:
        prefix: /opt
