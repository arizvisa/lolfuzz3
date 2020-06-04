acbuild begin --insecure docker://alpine:latest
acbuild set-name lol/radamsa

acbuild label add version 0.5
acbuild label add arch amd64
acbuild label add os linux
acbuild label add distro alpine

export git_owl_url=https://gitlab.com/owl-lisp/owl.git
export owl_version=0.1.12

export git_radamsa_url=https://gitlab.com/akihe/radamsa.git
export radamsa_version=0.5

acbuild run -- apk update
acbuild run -- apk add --virtual .build git curl build-base

acbuild run -- git clone "${git_owl_url}" /root/owl-lisp -b v${owl_version}
acbuild run --working-dir /root/owl-lisp -- make install

acbuild run -- git clone "${git_radamsa_url}" /root/radamsa -b v${radamsa_version}
acbuild run --working-dir /root/radamsa -- ol -O2 -o radamsa.c rad/main.scm
acbuild run --working-dir /root/radamsa -- make install

acbuild run -- rm -rf /root/owl-lisp /root/radamsa
acbuild run -- apk del .build

acbuild set-exec -- /usr/bin/radamsa

