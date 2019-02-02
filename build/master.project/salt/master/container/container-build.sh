#!/usr/bin/env bash
# Build images based on the rules within the filesystem
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:$CONTAINER_DIR
umask 027

BUILDDIR=${BUILDDIR:-"$CONTAINER_DIR/build"}
IMAGEDIR=${IMAGEDIR:-"$CONTAINER_DIR/image"}

[ ! -d "$BUILDDIR" ] && printf 'Build-directory "%s" is not found. Nothing needed to be built. Exiting.\n' "$BUILDDIR" 1>&2 && exit 0
[ ! -d "$IMAGEDIR" ] && printf 'Image-directory "%s" is not found. Creating it...\n' "$IMAGEDIR" 1>&2 && mkdir -p "$IMAGEDIR"

cd "$BUILDDIR" && for rule in *:*.acb *:*.{aci,oci}.{sh,bash,csh}; do
    build.sh "${rule}"
done
exit 0