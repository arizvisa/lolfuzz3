{%- import_yaml "acbuild.sls" as acbuild_files -%}

# configuration for the service responsible for building and deploying containers

service:
    container:
        paths:
            build: /srv/container/build
            image: /srv/container/image
            tools: /srv/container/tools
            service-tools: /srv/container

        # directories used to extract the tools listed below
        tools-extract:
            # temporary directory that archive gets extracted to
            temporary: /tmp/container

            # glob that matches the files that we care about from the archive
            match: '*/*'

        # the tools that get extracted
        tools:
            {% for file in acbuild_files -%}
            - {% for attribute in file -%}
              {{ attribute | yaml_dquote }}: {{ file[attribute] | yaml_dquote }}
              {% endfor %}
            {% endfor %}
