{%- import_yaml 'acbuild.sls' as acbuild_files -%}

master:
    # configuration for project services
    service:
        # service responsible for building and deploying containers
        container:
            Path: /srv/container
            Tools: {{ acbuild_files }}
