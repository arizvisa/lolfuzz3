{%- import_yaml 'acbuild.sls' as acbuild_files -%}

# configuration for the service responsible for building and deploying containers

master:
    service:
        container:
            Path: /srv/container
            Tools:
                {% for file in acbuild_files -%}
                - {% for attribute in file -%}
                  {{ attribute }}: {{ file[attribute] }}
                  {% endfor %}
                {% endfor %}
