#!/bin/sh
id_file={{ image_id_path }}

# Verify that the container for {{ image_name }} has already been fetched
if [ ! -e "$id_file" ]; then
    echo "Container {{ image_name }} has not been fetched. File $id_file does not exist!" 1>&2
    exit 1
fi

# Assign some default variables
id=`cat "$id_file"`
cwd=`pwd`
cache="$HOME/.mc"
image_uuid="$cache/.container-{{ image_name }}.$$"

# If the cache directory doesn't exist, then create it so that we
# can write the running container id to into it
if [ ! -d "$cache" ]; then
    mkdir -p "$cache"
fi

# Verify that the image_uuid file doesn't already exist
if [ -e "$image_uuid" ]; then
    uuid=`cat "$image_uuid"`
    echo "UUID file ($image_uuid) for container {{ image_name }} ($uuid) already exists or container is already running. Please stop container and remove file or try again." 1>&2
    exit 1
fi

# Enumerate all running containers and let the user know which are currently running
if ls "$cache/.{{ image_name }}".* 1>/dev/null 2>/dev/null; then
    for uuid_file in "$cache/.{{ image_name }}".*; do
        uuid=`cat "$uuid_file"`
        echo "Found a container for {{ image_name }} already running at $uuid." 1>&2
    done
fi

# Run container using the user parameters as arguments
"{{ rkt }}" run \
    "--uuid-file-save=$image_uuid" \
    {% for volume in volumes -%}
    --mount "volume={{ volume.name }},target={{ volume.mount }}" \
    --volume "{{ volume.name }},kind=host,source={{ volume.source }}" \
    {% endfor -%}
    {% for opt in rkt_options -%}
    '--{{ opt }}={{ "true" if rkt_options[opt] else "false" }}' \
    {% endfor -%}
    "$id" \
    '--readonly-rootfs=true' \
    "--working-dir=$cwd" \
    -- \
    "$@"
rc=$?

# Clean-up the finished container and remove the old uuid file
"{{ rkt }}" rm "--uuid-file=$image_uuid" 1>/dev/null
rm -f "$image_uuid"

# Return the original return code
exit $rc
