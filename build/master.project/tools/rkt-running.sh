#!/bin/sh
rkt list --format=json --no-legend | jq '.[] | select (.state == "running")'
