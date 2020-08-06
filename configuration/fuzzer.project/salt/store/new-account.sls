# This state is intended to be run from a reactor with state.single and
# requires the following parameters to be passed via a pillar:
#
#   accessKey: string
#   secretKey: string
#   ?groupName: string
#
# NOTE: The "secretKey" must be longer than 8-characters due to a constraint
#       imposed by the MinIO server.

{% set mpillar = salt["pillar.items"](pillarenv="master") %}
{% set bpillar = salt["pillar.items"](pillarenv="base") %}
{% set Root = mpillar["local"]["root"] %}

include:
    - store.deploy

Create a new account for the client:
    cmd.run:
        - name: >-
            /usr/bin/ssh
            -i "{{ Root }}{{ mpillar["toolbox"]["self-service"]["key"] }}"
            -o StrictHostKeyChecking=no
            -o UserKnownHostsFile=/dev/null
            --
            {{ mpillar["toolbox"]["self-service"]["host"] | yaml_squote }}
            sudo -i
            --
            {{ bpillar["store"]["minio"]["client"] }} --no-color
            admin user add
            local
            "{{ pillar.accessKey }}"
            "{{ pillar.secretKey }}"

        - require:
            - Configure the {{ bpillar["container"]["minio-client"]["name"] }} client

{% if "groupName" in pillar -%}
Add the newly created account for the client to a group:
    cmd.run:
        - name: >-
            /usr/bin/ssh
            -i "{{ Root }}{{ mpillar["toolbox"]["self-service"]["key"] }}"
            -o StrictHostKeyChecking=no
            -o UserKnownHostsFile=/dev/null
            --
            {{ mpillar["toolbox"]["self-service"]["host"] | yaml_squote }}
            sudo -i
            --
            {{ bpillar["store"]["minio"]["client"] }} --no-color
            admin group add
            local
            "{{ pillar.groupName }}"
            "{{ pillar.accessKey }}"
        - require:
            - Create a new account for the client
{% endif -%}
