# Translated from wurstmeiser/kafka-docker
# https://github.com/wurstmeister/kafka-docker

acbuild begin --insecure docker://openjdk:8u191-jre-alpine

acbuild set-name lol/apache-kafka

export KAFKA_VERSION=0.8.2.1
export SCALA_VERSION=2.11
export GLIBC_VERSION=2.29-r0

export rootfs=apache-kafka:${KAFKA_VERSION}
export tmp=/root

acbuild label add version ${KAFKA_VERSION}
acbuild label add arch amd64
acbuild label add os linux

acbuild environment add KAFKA_VERSION ${KAFKA_VERSION}
acbuild environment add SCALA_VERSION ${SCALA_VERSION}
acbuild environment add GLIBC_VERSION ${GLIBC_VERSION}
acbuild environment add KAFKA_HOME /opt/kafka

acbuild run -- apk add --no-cache bash curl jq

acbuild run -- mkdir -vp ${tmp}

for file in download-kafka.sh start-kafka.sh broker-list.sh create-topics.sh versions.sh; do
    acbuild copy ${rootfs}/${file} ${tmp}/${file}
    acbuild run -- chmod a+x ${tmp}/${file}
done

acbuild run -- mv -v ${tmp}/start-kafka.sh ${tmp}/broker-list.sh ${tmp}/create-topics.sh ${tmp}/versions.sh /usr/bin
acbuild run -- ${tmp}/download-kafka.sh ${tmp}
acbuild run -- tar xfz ${tmp}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt
acbuild run -- rm ${tmp}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
acbuild run -- ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka
acbuild run -- rm -vrf ${tmp}
acbuild run -- wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk
acbuild run -- apk add --no-cache --allow-untrusted glibc-${GLIBC_VERSION}.apk
acbuild run -- rm -v glibc-${GLIBC_VERSION}.apk

acbuild run -- mkdir -vp /opt/overrides
for path in ${rootfs}/overrides/*; do
    name=`basename "${path}"`
    acbuild copy ${path} /opt/overrides/${name}
done

acbuild mount add kafka-root /kafka
acbuild set-exec -- /usr/bin/start-kafka.sh
