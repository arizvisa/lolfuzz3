{% set mpillar = salt["pillar.items"](pillarenv="master") %}
{% set pillar = salt["pillar.items"](pillarenv="base") %}

{% set Root = mpillar["local"]["root"] %}

Create the {{ pillar["container"]["minio"]["name"] }}.service data store:
    file.directory:
        - name: '{{ Root }}/{{ pillar["store"]["minio"]["root"] }}'
        - mode: 0775
        - makedirs: true

Fetch the {{ pillar["container"]["minio"]["name"] }} image:
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
            --insecure-options=image
            fetch
            {{ pillar["container"]["minio"]["image"] }}:{{ pillar["container"]["minio"]["version"] }}
            >|
            "{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["minio"]["name"] }}:{{ pillar["container"]["minio"]["version"] }}.id"

        - creates: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["minio"]["name"] }}:{{ pillar["container"]["minio"]["version"] }}.id'

Check that the {{ pillar["container"]["minio"]["name"] }} image has been fetched:
    file.exists:
        - name: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["minio"]["name"] }}:{{ pillar["container"]["minio"]["version"] }}.id'
        - require:
            - Fetch the {{ pillar["container"]["minio"]["name"] }} image

Make dropin directory for {{ pillar["container"]["minio"]["name"] }}.service:
    file.directory:
        - name: {{ Root }}/etc/systemd/system/{{ pillar["container"]["minio"]["name"] }}.service.d
        - mode: 0755
        - makedirs: true

Install the {{ pillar["container"]["minio"]["name"] }}.service systemd unit:
    file.managed:
        - template: jinja
        - source: salt://store/minio.service
        - name: '{{ Root }}/etc/systemd/system/{{ pillar["container"]["minio"]["name"] }}.service'
        - defaults:
            arguments:
                - server
                - /data

            network: default
            exposed:
                - name: 9000-tcp
                  number: 9000

            volumes:
                - name: volume-data
                  mount: /data
                  source: {{ pillar["store"]["minio"]["root"] }}

            image_id_path: {{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["minio"]["name"] }}:{{ pillar["container"]["minio"]["version"] }}.id
            uuid_path: {{ pillar["container"]["minio"]["uuid"] }}

        - require:
            - Create the {{ pillar["container"]["minio"]["name"] }}.service data store
            - Check that the {{ pillar["container"]["minio"]["name"] }} image has been fetched
        - mode: 0664

Dropin an environment configuration to the {{ pillar["container"]["minio"]["name"] }}.service systemd unit:
    file.managed:
        - template: jinja
        - source: salt://store/minio-configuration.dropin
        - name: {{ Root }}/etc/systemd/system/{{ pillar["container"]["minio"]["name"] }}.service.d/50-configuration.conf
        - defaults:
            configuration:
                access_key: {{ mpillar["project"] }}
                secret_key: {{ mpillar["local"]["machine_id"] }}
                worm: "{{ "on" if pillar["store"]["minio"]["write-only-read-many"] else "off" }}"
                browser: "{{ "on" if pillar["store"]["minio"]["browser"] else "off" }}"
        - require:
            - Make dropin directory for {{ pillar["container"]["minio"]["name"] }}.service
            - Install the {{ pillar["container"]["minio"]["name"] }}.service systemd unit
        - mode: 0664

Enable systemd multi-user.target wants {{ pillar["container"]["minio"]["name"] }}.service:
    file.symlink:
        - name: '{{ Root }}/etc/systemd/system/multi-user.target.wants/{{ pillar["container"]["minio"]["name"] }}.service'
        - target: '/etc/systemd/system/{{ pillar["container"]["minio"]["name"] }}.service'
        - require:
            - Install the {{ pillar["container"]["minio"]["name"] }}.service systemd unit
            - Dropin an environment configuration to the {{ pillar["container"]["minio"]["name"] }}.service systemd unit
        - makedirs: true

Fetch the {{ pillar["container"]["minio-client"]["name"] }} image:
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
            --insecure-options=image
            fetch
            {{ pillar["container"]["minio-client"]["image"] }}:{{ pillar["container"]["minio-client"]["version"] }}
            >|
            "{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["minio-client"]["name"] }}:{{ pillar["container"]["minio-client"]["version"] }}.id"

        - creates: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["minio-client"]["name"] }}:{{ pillar["container"]["minio-client"]["version"] }}.id'

Check that the {{ pillar["container"]["minio-client"]["name"] }} image has been fetched:
    file.exists:
        - name: '{{ Root }}/{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["minio-client"]["name"] }}:{{ pillar["container"]["minio-client"]["version"] }}.id'
        - require:
            - Fetch the {{ pillar["container"]["minio-client"]["name"] }} image

Deploy the {{ pillar["container"]["minio-client"]["name"] }} command:
    file.managed:
        - template: jinja
        - source: salt://store/minio-client.command
        - name: {{ Root }}/{{ pillar["store"]["minio"]["client"] }}
        - defaults:
            rkt: /bin/rkt
            volumes:
                - name: home
                  mount: /root
                  source: $HOME

                - name: service
                  mount: /srv
                  source: /srv

            rkt_options:
                inherit-env: true
                interactive: true

            image_name: {{ pillar["container"]["minio-client"]["name"] }}
            image_id_path: {{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["minio-client"]["name"] }}:{{ pillar["container"]["minio-client"]["version"] }}.id
        - require:
            - Check that the {{ pillar["container"]["minio-client"]["name"] }} image has been fetched
        - mode: 0775
