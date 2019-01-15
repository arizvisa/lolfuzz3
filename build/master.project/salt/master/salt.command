#!/bin/sh
command=`basename "$0"`

uuid_file={{ run_uuid_path }}
if [ ! -e "$uuid_file" ]; then
    echo "Unit salt-master.service is not running: UUID file $uuid_file does not exist!" 1>&2
    exit 1
fi

uuid=`cat "$uuid_file"`
"{{ rkt }}" enter "$uuid" "$command" "$@"

exit $?
