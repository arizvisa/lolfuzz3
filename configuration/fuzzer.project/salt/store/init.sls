{% set mpillar = salt["pillar.items"](pillarenv="master") %}
{% set pillar = salt["pillar.items"](pillarenv="base") %}

{% set Root = mpillar["local"]["root"] %}

include:
    - store.deploy

{% for user in pillar["store"]["minio"]["users"] -%}
Create a new account ({{ user["accessKey"] }}) on the {{ pillar["container"]["minio"]["name"] }} server:
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
            {{ pillar["store"]["minio"]["client"] }} --no-color
            admin user add
            local
            "{{ user["accessKey"] }}"
            "{{ user["secretKey"] }}"
        - require:
            - sls: store.deploy

Add an account ({{ user["accessKey"] }}) to a group ({{ user["group"] }}) on the {{ pillar["container"]["minio"]["name"] }} server:
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
            {{ pillar["store"]["minio"]["client"] }} --no-color
            admin group add
            local
            "{{ user["group"] }}"
            "{{ user["accessKey"] }}"
        - require:
            - Create a new account ({{ user["accessKey"] }}) on the {{ pillar["container"]["minio"]["name"] }} server
{% endfor -%}

{% for group in pillar["store"]["minio"]["groups"] -%}
Set the {{ group["policy"] }} policy for the {{ group["name"] }} group on the {{ pillar["container"]["minio"]["name"] }} server:
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
            {{ pillar["store"]["minio"]["client"] }} --no-color
            admin policy set
            local
            "{{ group["policy"] }}"
            "group={{ group["name"] }}"
        - require:
            - sls: store.deploy
            {% for user in pillar["store"]["minio"]["users"] -%}
            - Add an account ({{ user["accessKey"] }}) to a group ({{ user["group"] }}) on the {{ pillar["container"]["minio"]["name"] }} server
            {% endfor %}
{% endfor -%}

{% for bucket in pillar["store"]["minio"]["buckets"] -%}
Create a bucket ({{ bucket["name"] }}) on the {{ pillar["container"]["minio"]["name"] }} server:
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
            {{ pillar["store"]["minio"]["client"] }} --no-color
            mb
            "local/{{ bucket["name"] }}"
        - require:
            - sls: store.deploy

Set the {{ bucket["policy"] }} policy for the {{ bucket["name"] }} bucket on the {{ pillar["container"]["minio"]["name"] }} server:
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
            {{ pillar["store"]["minio"]["client"] }} --no-color
            policy set
            "{{ bucket["policy"] }}"
            "local/{{ bucket["name"] }}"
        - require:
            - Create a bucket ({{ bucket["name"] }}) on the {{ pillar["container"]["minio"]["name"] }} server
{% endfor -%}
