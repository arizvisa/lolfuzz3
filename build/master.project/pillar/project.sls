{%- import_yaml 'project-name.sls' as project_name -%}

# project-specific configuration

master:
    configuration:
        project: {{ project_name }}
