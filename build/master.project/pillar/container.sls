{%- import_yaml "acbuild.sls" as acbuild_files -%}

# configuration for the service responsible for building and deploying containers

service:
    container:
        paths:
            base: /srv/container
            build: /srv/container/build
            image: /srv/container/image
            tools: /srv/container/tools
            service-tools: /srv/container

        tools:
            {% for file in acbuild_files -%}
            - {% for attribute in file -%}
              {{ attribute | yaml_dquote }}: {{ file[attribute] | yaml_dquote }}
              {% endfor %}
            {% endfor %}
