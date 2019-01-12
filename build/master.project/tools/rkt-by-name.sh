#!/bin/sh
machine_id=$1
rkt list --format=json --no-legend | jq '.[] | select (.state == "running" and .name == "'${machine_id}'")'
