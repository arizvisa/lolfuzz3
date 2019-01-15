#!/bin/sh
toolbox {%- for path in mounts %} --bind={{ path }}{% endfor %} -- "$@"
