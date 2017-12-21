#!/usr/bin/env bash
# Update images that are in the repository to the latest available
#   version on the filesystem according to the timestamp.

export PATH=/sbin:/bin:/usr/sbin:/usr/bin
umask 077

IMAGEDIR=${IMAGEDIR:-"$CONTAINER_DIR/image"}

# ripped from stackoverflow.com/questions/4023830
ver_le()
{
    [ "$1" = "`echo -e \"$1\n$2\" | sort -V | head -n1`" ]
}
ver_lt()
{
    [ "$1" = "$2" ] && return 1 || ver_le "$1" "$2"
}

# Get the image name from the argument
name="$1"

# Enumerate all images that match the requested name
rkt image list --full=true --no-legend=true --fields=name,id,importtime | grep -e "^${name}:" | while read imgfull id ts; do
    [ -z "${id}" ] && continue

    # Remove the tzinfo from the timestamp
    tss=`echo -n "${ts}" | cut -d' ' -f1,2`

    # Extract the different components out of the image list
    imgname=`basename "${imgfull}" | cut -d: -f1`
    imgver=`basename "${imgfull}" | cut -d: -f2`
    imgts=`date +%s -d "${tss}"`

    # Find the image file named $imgname with the newest version.
    file=`ls -1 "$IMAGEDIR/${imgname}:"*.{aci,oci} 2>/dev/null | sort -Vr | head -n1`
    if [ -z "${file}" ]; then
        printf 'No versions for image %s (%s) were found on disk!\n' "${imgname}" "${id}" 1>&2
        continue
    fi

    # Figure out what image type it is.
    case "${file}" in
        *.aci) suffix='.aci' ;;
        *.oci) suffix='.oci' ;;
        *)
            printf 'Unknown image suffix for file %s. Skipping.\n' "${file}" 1>&2
            continue
            ;;
    esac

    filefull=`basename "${file}" "${suffix}"`
    filename=`basename "${filefull}" | cut -d: -f1`
    filever=`basename "${filefull}" | cut -d: -f2`
    filets=`stat -c%Y "${file}"`

    # If versions are the same and the img is newer than the file, then we don't need to update.
    [ "${imgver}" = "${filever}" -a "${filets}" -le "${imgts}" ] && continue

    # Assert that the file version is >= the image version.
    if ver_lt "${filever}" "${imgver}"; then
        printf 'Image %s on disk is a lesser version than in image list! (%s < %s)\n' "${filefull}" "${filever}" "${imgver}" 1>&2
        printf $'%s\t%s\t%s\n' "${imgname}" "${imgver}" "${id}"
        continue
    fi

    # This would mean that either there's an updated version, or a newer timestamp.
    if [ "${imgver}" != "${filever}" ]; then
        printf 'Image %s:%s (%s) needs to be updated to version %s.\n' "${imgname}" "${imgver}" "${id}" "${filever}" 1>&2
    else
        printf 'Image %s:%s needs to be synced with %s. (%s)\n' "${imgname}" "${imgver}" "${filefull}" "${id}" 1>&2
    fi

    # So remove the image from rkt if it's not running...
    task_count=`rkt list --full=true --no-legend=true | cut -f3,5 | grep "^${imgname}:" | grep $'\t'"running$" | wc -l`
    if [ "${task_count}" -gt 0 ]; then
        printf 'Refusing to remove image %s:%s as it'\''s still in use!\n' "${imgname}" "${imgver}" 1>&2
    else
        printf 'Removing old image %s:%s due to it not being in use.\n' "${imgname}" "${imgver}" 1>&2
        rkt image rm "${id}" 1>&2
    fi

    # ...and then fe-fetch it securely if a signature was found.
    if [ -f "$IMAGEDIR"/"${imgname}:${imgver}.asc" ]; then
        printf 'Loading image (secrely) for %s:%s.\n' "${filename}" "${filever}" 1>&2
        res=`rkt image fetch file://"${file}"`
    # ...and insecurely if not.
    else
        printf 'Loading image (insecurely) for %s:%s.\n' "${filename}" "${filever}" 1>&2
        res=`rkt --insecure-options=image image fetch file://"${file}"`
    fi

    [ -z "${res}" ] && printf 'Error loading image %s:%s\n' "${filename}" "${filever}" 1>&2 && continue

    printf $'%s\t%s\t%s\n' "${filename}" "${filever}" "${res}"
done

exit 0
