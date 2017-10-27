#!/bin/sh
sed=`type -P sed`

# FIXME: should probably process with a json parser to deal with inconsistencies

"${sed}" -e '
s/"winrm_username": "vagrant",$/"winrm_username": "{{user `default-username`}}",/g;
s/"winrm_password": "vagrant",$/"winrm_password": "{{user `default-password`}}",/g;
s/"ssh_username": "vagrant",$/"ssh_username": "{{user `default-username`}}",/g;
s/"ssh_password": "vagrant",$/"ssh_password": "{{user `default-password`}}",/g;
s/"vm_name": "[^"]*",$/"vm_name": "{{user `machine-name`}}",/g
' "$@"

# FIXME: add the following to each builder
    "http_directory" : "{{user `install-input`}}",
    "output_directory" : "{{user `install-output`}}",

# FIXME: modify /provisioners/*/environment_vars to include
    "HTTP_IP={{.HTTPIP}}",
    "HTTP_PORT={{.HTTPPort}}",
