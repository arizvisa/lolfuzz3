container:
    zetcd:
        name: zetcd
        image: quay.io/coreos/zetcd
        version: v0.0.5
        uuid: /var/lib/coreos/zetcd.uuid

    kafka:
        name: apache-kafka
        image: lol/apache-kafka
        version: 2.0.1
        uuid: /var/lib/coreos/apache-kafka.uuid

queue:
    kafka:
        # Configuration for apache kafka
        root: /srv/kafka

        # These are the defaults set by zetcd
        zookeeper:
            host: 127.0.0.1
            port: 2181

        listeners:
            - protocol: plaintext
              host: 127.0.0.1
              port: 9092

        tools:
            kafka-topics.sh: /opt/kafka/bin/kafka-topics.sh
            kafka-console-consumer.sh: /opt/kafka/bin/kafka-console-consumer.sh
            kafka-console-producer.sh: /opt/kafka/bin/kafka-console-producer.sh
            zookeeper-shell.sh: /opt/kafka/bin/zookeeper-shell.sh
