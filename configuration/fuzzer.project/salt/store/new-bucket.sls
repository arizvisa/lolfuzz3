# This state is intended to be run with a state.single and requires the
# following parameters to be passed via a pillar:
#
#   name: string
#   policy: string
#   ?archive: string
#

{% set mpillar = salt["pillar.items"](pillarenv="master") %}
{% set bpillar = salt["pillar.items"](pillarenv="base") %}
{% set Root = mpillar["local"]["root"] %}

include:
    - store.deploy

Create a bucket ({{ pillar.name }}) on the {{ bpillar["container"]["minio"]["name"] }} server:
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
            mb
            "local/{{ pillar.name }}"
        - unless: >-
            /usr/bin/ssh
            -i "{{ Root }}{{ mpillar["toolbox"]["self-service"]["key"] }}"
            -o StrictHostKeyChecking=no
            -o UserKnownHostsFile=/dev/null
            --
            {{ mpillar["toolbox"]["self-service"]["host"] | yaml_squote }}
            sudo -i
            --
            {{ bpillar["store"]["minio"]["client"] }} --no-color
            ls
            "local/{{ pillar.name }}"

        - require:
            - Configure the {{ bpillar["container"]["minio-client"]["name"] }} client

Set the {{ pillar.policy }} policy for the {{ pillar.name }} bucket on the {{ bpillar["container"]["minio"]["name"] }} server:
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
            policy set
            "{{ pillar.policy }}"
            "local/{{ pillar.name }}"
        - require:
            - Create a bucket ({{ pillar.name }}) on the {{ bpillar["container"]["minio"]["name"] }} server

{% if "archive" in pillar -%}
Initialize the {{ pillar.name }} bucket with the contents of an archive:
    archive.extracted:
        - name: {{ Root }}/srv/store/{{ pillar.name }}
        - source: {{ pillar.archive }}
        - skip_verify: true
        - keep_source: false
        - overwrite: true
        - enforce_toplevel: false
        - user: root
        - group: root
        - require:
            - Create a bucket ({{ pillar.name }}) on the {{ bpillar["container"]["minio"]["name"] }} server
{% endif -%}
