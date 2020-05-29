{% set mpillar = salt["pillar.items"](pillarenv="master") %}
{% set pillar = salt["pillar.items"](pillarenv="base") %}

{% set Root = mpillar["local"]["root"] %}

Check that the radamsa container exists:
    file.exists:
        - name: '{{ Root }}{{ mpillar["service"]["container"]["paths"]["build"] }}/{{ pillar["container"]["radamsa"]["name"] }}:{{ pillar["container"]["radamsa"]["version"] }}.aci.sh'

Build the radamsa image:
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
            "{{ mpillar["service"]["container"]["paths"]["build"] }}/{{ pillar["container"]["radamsa"]["name"] }}:{{ pillar["container"]["radamsa"]["version"] }}.aci.sh"

        - creates: '{{ Root }}{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["radamsa"]["name"] }}:{{ pillar["container"]["radamsa"]["version"] }}.aci'

        - require:
            - Check that the radamsa container exists

Load the radamsa image:
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
            "{{ mpillar["service"]["container"]["paths"]["service-tools"] }}/load.sh"
            "{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["radamsa"]["name"] }}:{{ pillar["container"]["radamsa"]["version"] }}.aci"
            |
            cut -d$'\t' -f3
            >|
            "{{ Root }}{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["radamsa"]["name"] }}:{{ pillar["container"]["radamsa"]["version"] }}.id"

        - creates: '{{ Root }}{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["radamsa"]["name"] }}:{{ pillar["container"]["radamsa"]["version"] }}.id'

        - require:
            - Build the radamsa image

Check that the radamsa image has been loaded:
    file.exists:
        - name: '{{ Root }}{{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["radamsa"]["name"] }}:{{ pillar["container"]["radamsa"]["version"] }}.id'
        - require:
            - Load the radamsa image

Deploy the radamsa command:
    file.managed:
        - template: jinja
        - source: salt://fuzzer/radamsa.command
        - name: {{ Root }}{{ pillar["fuzzer"]["radamsa"] }}
        - defaults:
            rkt: /bin/rkt
            cachedir: $HOME/.radamsa

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

            image_name: {{ pillar["container"]["radamsa"]["name"] }}
            image_id_path: {{ mpillar["service"]["container"]["paths"]["image"] }}/{{ pillar["container"]["radamsa"]["name"] }}:{{ pillar["container"]["radamsa"]["version"] }}.id

        - require:
            - Check that the radamsa image has been loaded
        - mode: 0775
