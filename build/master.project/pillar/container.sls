{%- import_yaml 'acbuild.sls' as acbuild_files -%}

master:
    service:
        container:
            path: /srv/container
            acbuild: {{ acbuild_files }}
