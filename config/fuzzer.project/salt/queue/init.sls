{% set mpillar = salt["pillar.items"](pillarenv="master") %}
{% set pillar = salt["pillar.items"](pillarenv="base") %}

{% set Root = mpillar["local"]["root"] %}

Fetch the zetcd image:
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
            fetch
            {{ pillar["container"]["zetcd"]["image"] }}:{{ pillar["container"]["zetcd"]["version"] }}
            >|
            "{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["zetcd"]["name"] }}:{{ pillar["container"]["zetcd"]["version"] }}.id"

        - creates: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["zetcd"]["name"] }}:{{ pillar["container"]["zetcd"]["version"] }}.id'

Check that the zetcd image has been fetched:
    file.exists:
        - name: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["zetcd"]["name"] }}:{{ pillar["container"]["zetcd"]["version"] }}.id'
        - require:
            - Fetch the zetcd image

Install the zetcd.service systemd unit:
    file.managed:
        - template: jinja
        - source: salt://queue/zetcd.service
        - name: '{{ Root }}/etc/systemd/system/zetcd.service'
        - defaults:
            network: host
            arguments:
                - --endpoints
                - http://127.0.0.1:2379

            image_id_path: {{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["zetcd"]["name"] }}:{{ pillar["container"]["zetcd"]["version"] }}.id
            uuid_path: {{ pillar["container"]["zetcd"]["uuid"] }}

        - require:
            - Check that the zetcd image has been fetched
        - mode: 0664

Enable systemd multi-user.target wants zetcd.service:
    file.symlink:
        - name: '{{ Root }}/etc/systemd/system/multi-user.target.wants/zetcd.service'
        - target: '/etc/systemd/system/zetcd.service'
        - require:
            - Install the zetcd.service systemd unit
        - makedirs: true

Check that the apache-kafka container exists:
    file.exists:
        - name: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["build"] }}/{{ pillar["container"]["kafka"]["name"] }}:{{ pillar["container"]["kafka"]["version"] }}.aci.sh'

Build the apace-kafka image:
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
            - Check that the apache-kafka container exists

Install the apache-kafka.service systemd unit:
    file.managed:
        - template: jinja
        - source: salt://queue/kafka.service
        - name: '{{ Root }}/etc/systemd/system/apache-kafka.service'
        - defaults:
            container_name: {{ pillar["container"]["kafka"]["image"] }}:{{ pillar["container"]["kafka"]["version"] }}
            image_name: {{ pillar["container"]["kafka"]["name"] }}:{{ pillar["container"]["kafka"]["version"] }}
            uuid_path: {{ pillar["container"]["kafka"]["uuid"] }}

            configuration:
                zookeeper_connect: 127.0.0.1:2181
                broker_id: 0
                listeners: PLAINTEXT://{{ mpillar["local"]["ip4"] }}:9092

            volumes:
                - name: kafka-root
                  mount: /kafka
                  source: /srv/kafka

            container_service_path: {{ mpillar["service"]["container"]["paths"]["service-tools"] }}
            container_image_path: {{ mpillar["service"]["container"]["paths"]["image"] }}

        - require:
            - Install the zetcd.service systemd unit
            - Build the apace-kafka image
        - mode: 0664

{% for toolname in pillar["queue"]["kafka"]["tools"] -%}
Install Tool for Apache Kafka -- {{ toolname }}:
    file.managed:
        - template: jinja
        - source: salt://queue/kafka.command
        - name: {{ Root }}/opt/bin/{{ toolname }}
        - defaults:
            rkt: /bin/rkt
            unit: apache-kafka.service
            run_uuid_path: {{ pillar["container"]["kafka"]["uuid"] }}

            command: {{ pillar["queue"]["kafka"]["tools"][toolname] }}
        - require:
            - Install the apache-kafka.service systemd unit
        - mode: 0775
{% endfor %}
