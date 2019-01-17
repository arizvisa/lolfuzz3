{%- import_yaml 'acbuild.sls' as acbuild_files -%}

# configuration for the service responsible for building and deploying containers

master:
    service:
        container:
            Path: /srv/container
            Tools: {{ acbuild_files }}
