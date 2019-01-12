#!/bin/sh
id=$1
rkt image list --format=json --no-legend | jq '.[] | select (.id == "'${id}'")'
