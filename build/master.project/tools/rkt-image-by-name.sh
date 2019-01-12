#!/bin/sh
name=$1
rkt image list --format=json --no-legend | jq '.[] | select (.name | startswith("'${name}':"))'
