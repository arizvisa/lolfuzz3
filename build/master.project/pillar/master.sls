{%- import_yaml 'project-name.sls' as project_name -%}

master:
    # configuration for project services
    service:
        # manages all the hosts in a project
        salt-master:
            Namespace: "/coreos.com/salt"
            Version: 2019.2
            UUID: /var/lib/coreos/salt-master.uuid

    # configuration for any extra scripts/tools
    tools:
        prefix: /opt
    
    # project-specific configuration
    configuration:
        project: {{ project_name }}
