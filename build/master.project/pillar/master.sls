{%- import_yaml 'project.sls' as project_config -%}

master:
    service:
        salt:
            version: 0.0.1
    
    project: {{ project_config }}
