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

store:
    minio:
        root: /srv/store
        client: /opt/bin/mc

        browser: true
        write-only-read-many: false
