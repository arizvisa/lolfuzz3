#!/usr/bin/env bash
# Add a versioned image into the rkt repository.
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
umask 077

# ripped from stackoverflow.com/questions/4023830
ver_le()
{
    [ "$1" = "`echo -e \"$1\n$2\" | sort -V | head -n1`" ]
}
ver_lt()
{
    [ "$1" = "$2" ] && return 1 || ver_le "$1" "$2"
}

# Check to see if the image exists
file="$1"
[ ! -f "${file}" ] && printf 'Image %s not found. Terminating.\n' "${rule}" 1>&2 && exit 1
base=`dirname "${file}"`

# Figure out the image type
case "${file}" in
    *.aci) suffix='.aci' ;;
    *.oci) suffix='.oci' ;;
    *)
        printf 'Unknown image suffix for file %s. Terminating.\n' "${file}" 1>&2
        exit 1
        ;;
esac


# Validate it with actool if it's an .aci file.
if [ "${suffix}" = ".aci" ]; then
    if actool validate "${file}" 2>/dev/null; then
        :
    else
        printf 'Image "%s" is invalid. Terminating.\n' "${file}" 1>&2
        exit 1
    fi
fi

# Extract the difference components out of the filename.
filefull=`basename "${file}" "${suffix}"`
filename=`basename "${filefull}" | cut -d: -f1`
filever=`basename "${filefull}" | cut -d: -f2-`

# If image name exists in the list of current images..
matched=`rkt image list --format=json | jq -c --arg name "$filename" 'map((.name | split("/") | .[-1]) as $image | . * {image_name: $image | split(":") | .[0], image_version: $image | split(":") | .[-1]}) | map(select(.image_name == $name)) | sort_by(.version) | .[0]'`
if [ "${matched}" != "null" ]; then

    # ...but the image version is less than the one loaded, then skip it.
    loadedname=`echo -n "${matched}" | jq -r '.name'`
    loadedver=`echo -n "${matched}" | jq -r '.image_version'`
    loadedid=`echo -n "${matched}" | jq -r '.image_name'`
    ver_le "${filever}" "${loadedver}" && printf 'Image file for %s is older than the one currently running (%s <= %s). No need to re-load it. Skipping.\n' "${file}" "${filever}" "${loadedver}" 1>&2 && printf $'%s\t%s\t%s\n' "${file}" "${loadedver}" "${loadedid}" && exit 0

    # otherwise, remove it and continue...
    printf 'Removing older image %s from list. : %s > %s.\n' "${filename}" "${filever}" "${loadedver}" 1>&2
    rkt image rm "$loadedname" 1>&2
fi

# Try and load the image insecurely if a signature was found.
if [ -f "${base}"/"${file}.asc" ]; then
    printf 'Loading image for %s:%s.\n' "${filename}" "${filever}" 1>&2
    res=`rkt image fetch file://"${base}"/"${filefull}${suffix}" 2>/dev/null`
# Otherwise, load it insecurely.
else
    printf 'Loading image (insecurely) for %s:%s.\n' "${filename}" "${filever}" 1>&2
    res=`rkt --insecure-options=image image fetch file://"${base}"/"${filefull}${suffix}" 2>/dev/null`
fi

if [ -z "${res}" ]; then
    printf 'Error loading image %s:%s\n' "${filename}" "${filever}" 1>&2
    exit 1
fi

# ..and then output our result.
printf $'%s\t%s\t%s\n' "${filename}" "${filever}" "${res}"

exit 0
