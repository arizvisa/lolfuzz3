#!/usr/bin/env bash
# Add images into the repository using the images available on the filesystem.

IMAGEDIR=${IMAGEDIR:-"$CONTAINER_DIR/image"}

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:$CONTAINER_DIR
umask 077

[ ! -d "$IMAGEDIR" ] && printf 'Image-directory "%s" is not found. Exiting...\n' "$IMAGEDIR" 1>&2 && exit 1

# Build all images that aren't in our containers
cd "$IMAGEDIR" && for file in *:*.{aci,oci}; do
    [ ! -f "${file}" ] && continue
    p=`realpath "${file}"`

    load.sh "${p}"
done

exit 0
