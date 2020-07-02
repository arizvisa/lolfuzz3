container:
    minio:
        name: minio
        image: docker://minio/minio
        version: latest
        uuid: /var/lib/coreos/minio.uuid

    minio-client:
        name: minio-client
        image: docker://minio/mc
        version: latest
        uuid: /var/lib/coreos/minio-client.uuid

{% import_yaml "/srv/bootstrap/pillar/configuration-name.sls" as project_name -%}
store:
    minio:
        root: /srv/store
        client: /opt/bin/mc

        browser: true
        write-only-read-many: false

        users:
            - accessKey: {{ grains["id"] }}
              secretKey: {{ project_name }}.lol
              group: minion

        groups:
            - name: minion
              policy: readwrite

        buckets:
            - name: empty
              policy: none
