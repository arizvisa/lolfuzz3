#!/usr/bin/env bash
# Build an image based on the rules within the filesystem

export IMAGEDIR=${IMAGEDIR:-"/var/lib/containers"}

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/opt/sbin:/opt/bin
umask 027

# Check for existence of the acbuild tool.
ACBUILD=${ACBUILD:-"`type -P acbuild 2>/dev/null`"}
if [ ! -x "$ACBUILD" ]; then
    # If not, then check to see if we can internet...
    printf '`%s` not found on host.\n' 'acbuild' 1>&2
    printf 'Unable to locate acbuild tool in path. Unable to build the requested image.\n' 1>&2
    exit 1
fi

# Check existence of the rule provided as the argument.
rule=`readlink -f "$1"`
[ ! -f "${rule}" ] && printf 'Rule %s not found. Terminating.\n' "${rule}" 1>&2 && exit 1
ruledir=`dirname "${rule}"`

case "$rule" in
# If this is an acbuild-type rule.
*.acb)
    printf 'Discovered an acbuild-type rule in %s.\n' "${rule}" 1>&2

    imgfull=`basename "${rule}" .acb`
    imgname=`basename "${imgfull}" | cut -d: -f1`
    imgver=`basename "${imgfull}" | cut -d: -f2`

    imgfile="${imgname}:${imgver}.aci"
    [ -f "$IMAGEDIR/${imgfile}" ] && printf 'Skipping build of %s due to %s already existing.\n' "${imgfull}" "$IMAGEDIR/${imgfile}" 1>&2 && printf $'%s\t%s\n' "${imgname}" "${imgver}" && exit 0

    pushd "${ruledir}" >/dev/null
    cat "${rule}" <( printf 'write --overwrite %s\n' "$IMAGEDIR/${imgfile}" ) | "$ACBUILD" script /dev/stdin
    err=$?
    popd >/dev/null

    if [ $err -ne 0 ] || [ ! -f "$IMAGEDIR/${imgname}:${imgver}.aci" ]; then
        printf 'Error trying to build image: "%s:%s"\n' "${imgname}" "${imgver}" 1>&2
        rm -f "$IMAGEDIR/${imgname}:${imgver}.aci"
        exit 1
    fi

    printf 'Successfully built image "%s:%s" at %s.\n' "${imgname}" "${imgver}" "$IMAGEDIR/${imgname}:${imgver}.aci" 1>&2
    printf $'%s\t%s\n' "${imgname}" "${imgver}"
    exit 0
    ;;

# If it's a shell-script, then passthru down below.
*.aci.sh|*.oci.sh|*.aci.bash|*.oci.bash|*.aci.csh|*.oci.csh)
    printf 'Discovered a shellscript-type rule in %s.\n' "${rule}" 1>&2
    ;;

# Couldn't figure it out...so leave.
*)
    printf 'Unknown image/script type for script %s. Terminating.\n' "${rule}" 1>&2
    exit 1
    ;;
esac

# Figure out how to execute script
case "${rule}" in
    *.sh) shtype="sh" ;;
    *.bash) shtype="bash" ;;
    *.csh) shtype="csh" ;;
    *)
        printf 'Unknown shell type for script %s. Terminating.\n' "${rule}" 1>&2
        exit 1
        ;;
esac
imgfile=`basename "${rule}" ."${shtype}"`

# Figure out the container type that's supposed to be emitted
case "${imgfile}" in
    *.aci) imgtype='.aci' ;;
    *.oci) imgtype='.oci' ;;
    *)
        printf 'Unknown container type for script %s. Terminating.\n' "${rule}" 1>&2
        exit 1
        ;;
esac

# Extract components from filename.
imgfull=`basename "${imgfile}" "${imgtype}"`
imgname=`basename "${imgfull}" | cut -d: -f1`
imgver=`basename "${imgfull}" | cut -d: -f2`

imgfile="${imgname}:${imgver}${imgtype}"
[ -f "$IMAGEDIR/${imgfile}" ] && printf 'Skipping build of %s due to %s already existing.\n' "${imgfull}" "$IMAGEDIR/${imgfile}" 1>&2 && printf $'%s\t%s\n' "${imgname}" "${imgver}" && exit 0

printf 'Found rule for "%s:%s" to write image to %s.\n' "${imgname}" "${imgver}" "$IMAGEDIR/${imgname}:${imgver}${imgtype}" 1>&2

imgtemp="$IMAGEDIR/${imgfull}.tmp"
trap "[ -f \"${imgtemp}\" ] && /bin/rm -f \"${imgtemp}\"; exit" SIGHUP SIGINT SIGTERM

# And now we can execute it..
pushd "${ruledir}" >/dev/null
cat "${rule}" <( printf 'acbuild write --overwrite %s\nacbuild end\n' "${imgtemp}" ) | "${shtype}" /dev/stdin
err=$?
popd >/dev/null

if [ $err -ne 0 ] || [ ! -f "${imgtemp}" ]; then
    printf 'Error trying to build image for rule "%s".\n' "${rule}" 1>&2
    rm -f "${imgtemp}"
    exit 1
else
    mv -f "${imgtemp}" "$IMAGEDIR/${imgfile}"
fi

# ..and now we can inform the user that it's there.
printf 'Successfully built image "%s:%s" at %s.\n' "${imgname}" "${imgver}" "$IMAGEDIR/${imgfile}" 1>&2
printf $'%s\t%s\n' "${imgname}" "${imgver}"

exit 0

