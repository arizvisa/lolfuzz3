{% set mpillar = salt["pillar.items"](pillarenv="master") %}
{% set pillar = salt["pillar.items"](pillarenv="base") %}

{% set Root = mpillar["local"]["root"] %}

Fetch the {{ pillar["container"]["zetcd"]["name"] }} image:
    cmd.run:
        - name: >-
            /usr/bin/ssh
            -i "{{ Root }}{{ mpillar["toolbox"]["self-service"]["key"] }}"
            -o StrictHostKeyChecking=no
            -o UserKnownHostsFile=/dev/null
            --
            {{ mpillar["toolbox"]["self-service"]["host"] | yaml_squote }}
            sudo
            --
            /bin/rkt
            --trust-keys-from-https
            fetch
            {{ pillar["container"]["zetcd"]["image"] }}:{{ pillar["container"]["zetcd"]["version"] }}
            | tail -n 1
            >|
            "{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["zetcd"]["name"] }}:{{ pillar["container"]["zetcd"]["version"] }}.id"

        - creates: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["zetcd"]["name"] }}:{{ pillar["container"]["zetcd"]["version"] }}.id'

Check that the {{ pillar["container"]["zetcd"]["name"] }} image has been fetched:
    file.exists:
        - name: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["zetcd"]["name"] }}:{{ pillar["container"]["zetcd"]["version"] }}.id'
        - require:
            - Fetch the {{ pillar["container"]["zetcd"]["name"] }} image

Install the {{ pillar["container"]["zetcd"]["name"] }}.service systemd unit:
    file.managed:
        - template: jinja
        - source: salt://queue/zetcd.service
        - name: '{{ Root }}/etc/systemd/system/{{ pillar["container"]["zetcd"]["name"] }}.service'
        - defaults:
            network: host
            arguments:
                - --endpoints
                - http://127.0.0.1:2379

            image_id_path: {{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["zetcd"]["name"] }}:{{ pillar["container"]["zetcd"]["version"] }}.id
            uuid_path: {{ pillar["container"]["zetcd"]["uuid"] }}

        - require:
            - Check that the {{ pillar["container"]["zetcd"]["name"] }} image has been fetched
        - mode: 0664

Enable systemd multi-user.target wants {{ pillar["container"]["zetcd"]["name"] }}.service:
    file.symlink:
        - name: '{{ Root }}/etc/systemd/system/multi-user.target.wants/{{ pillar["container"]["zetcd"]["name"] }}.service'
        - target: '/etc/systemd/system/{{ pillar["container"]["zetcd"]["name"] }}.service'
        - require:
            - Install the {{ pillar["container"]["zetcd"]["name"] }}.service systemd unit
        - makedirs: true

Check that the {{ pillar["container"]["kafka"]["name"] }} container exists:
    file.exists:
        - name: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["build"] }}/{{ pillar["container"]["kafka"]["name"] }}:{{ pillar["container"]["kafka"]["version"] }}.aci.sh'

Build the {{ pillar["container"]["kafka"]["name"] }} image:
    cmd.run:
        - name: >-
            /usr/bin/ssh
            -i "{{ Root }}{{ mpillar["toolbox"]["self-service"]["key"] }}"
            -o StrictHostKeyChecking=no
            -o UserKnownHostsFile=/dev/null
            --
            {{ mpillar["toolbox"]["self-service"]["host"] | yaml_squote }}
            sudo
            "IMAGEDIR={{ mpillar["service"]["container"]["paths"]["image"] }}"
            "TOOLSDIR={{ mpillar["service"]["container"]["paths"]["tools"] }}"
            --
            "{{ mpillar["service"]["container"]["paths"]["service-tools"] }}/build.sh"
            "{{ mpillar["service"]["container"]["paths"]["build"] }}/{{ pillar["container"]["kafka"]["name"] }}:{{ pillar["container"]["kafka"]["version"] }}.aci.sh"

        - creates: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["kafka"]["name"] }}:{{ pillar["container"]["kafka"]["version"] }}.aci'
        - require:
            - Check that the {{ pillar["container"]["kafka"]["name"] }} container exists

Make the kafka-root directory for the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit:
    file.directory:
        - name: '{{ Root }}{{ pillar["queue"]["root"] }}'
        - mode: 0755
        - makedirs: true

Make dropin directory for {{ pillar["container"]["kafka"]["name"] }}.service:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/{{ pillar["container"]["kafka"]["name"] }}.service.d
        - mode: 0755
        - makedirs: true

Install the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit:
    file.managed:
        - template: jinja
        - source: salt://queue/kafka.service
        - name: '{{ Root }}/etc/systemd/system/{{ pillar["container"]["kafka"]["name"] }}.service'
        - defaults:
            dependencies:
                - {{ pillar["container"]["zetcd"]["name"] }}.service

            container_name: {{ pillar["container"]["kafka"]["image"] }}:{{ pillar["container"]["kafka"]["version"] }}
            image_name: {{ pillar["container"]["kafka"]["name"] }}:{{ pillar["container"]["kafka"]["version"] }}
            uuid_path: {{ pillar["container"]["kafka"]["uuid"] }}

            volumes:
                - name: kafka-root
                  mount: /kafka
                  source: {{ pillar["queue"]["root"] }}

            container_service_path: {{ mpillar["service"]["container"]["paths"]["service-tools"] }}
            container_image_path: {{ mpillar["service"]["container"]["paths"]["image"] }}

        - require:
            - Install the {{ pillar["container"]["zetcd"]["name"] }}.service systemd unit
            - Build the {{ pillar["container"]["kafka"]["name"] }} image
            - Make the kafka-root directory for the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit
        - mode: 0664

Dropin an environment configuration to the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit:
    file.managed:
        - template: jinja
        - source: salt://queue/kafka-configuration.dropin
        - name: {{ Root }}/etc/systemd/system/{{ pillar["container"]["kafka"]["name"] }}.service.d/50-configuration.conf
        - defaults:
            configuration:
                zookeeper_connect: {{ pillar["queue"]["zookeeper"]["host"] }}:{{ pillar["queue"]["zookeeper"]["port"] }}
                broker_id: 0
                listeners: PLAINTEXT://{{ mpillar["local"]["ip4"] }}:9092
        - require:
            - Make dropin directory for {{ pillar["container"]["kafka"]["name"] }}.service
            - Install the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit
        - mode: 0664

Enable systemd multi-user.target wants {{ pillar["container"]["kafka"]["name"] }}.service:
    file.symlink:
        - name: '{{ Root }}/etc/systemd/system/multi-user.target.wants/{{ pillar["container"]["kafka"]["name"] }}.service'
        - target: '/etc/systemd/system/{{ pillar["container"]["kafka"]["name"] }}.service'
        - require:
            - Install the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit
            - Dropin an environment configuration to the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit
        - makedirs: true

Start the {{ pillar["container"]["kafka"]["name"] }}.service unit:
    cmd.run:
        - name: >-
            /usr/bin/ssh
            -i "{{ Root }}{{ mpillar["toolbox"]["self-service"]["key"] }}"
            -o StrictHostKeyChecking=no
            -o UserKnownHostsFile=/dev/null
            --
            {{ mpillar["toolbox"]["self-service"]["host"] | yaml_squote }}
            sudo
            --
            systemctl start {{ pillar["container"]["kafka"]["name"] }}.service

        - require:
            - Enable systemd multi-user.target wants {{ pillar["container"]["kafka"]["name"] }}.service

{% for toolname in pillar["queue"]["tools"] -%}
Install tool for {{ pillar["container"]["kafka"]["name"] }} image -- {{ toolname }}:
    file.managed:
        - template: jinja
        - source: salt://queue/kafka.command
        - name: {{ Root }}/opt/bin/{{ toolname }}
        - defaults:
            rkt: /bin/rkt
            unit: {{ pillar["container"]["kafka"]["name"] }}.service
            run_uuid_path: {{ pillar["container"]["kafka"]["uuid"] }}

            command: {{ pillar["queue"]["tools"][toolname] }}
        - require:
            - Install the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit
            - Dropin an environment configuration to the {{ pillar["container"]["kafka"]["name"] }}.service systemd unit
        - mode: 0775
{% endfor %}
