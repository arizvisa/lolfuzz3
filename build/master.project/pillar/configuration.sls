{%- import_yaml "configuration-name.sls" as project_name -%}

# configuration for bootstrapping project
configuration:

    # project name and path
    name: {{ project_name | yaml_dquote }}
    path: 'git://path/to/{{ project_name }}/repository'

    # default configuration bootstrapped into etcd
    defaults:
        service: {}
        template: {}
        pod: {}
