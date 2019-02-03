{%- import_yaml "acbuild.sls" as acbuild_files -%}

# configuration for the service responsible for building and deploying containers

service:
    container:
        path: /srv/container
        tools:
            {% for file in acbuild_files -%}
            - {% for attribute in file -%}
              {{ attribute | yaml_dquote }}: {{ file[attribute] | yaml_dquote }}
              {% endfor %}
            {% endfor %}
