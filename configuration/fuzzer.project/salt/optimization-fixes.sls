{% if grains["os_family"] == "Windows" -%}
Modify the TimeOutValue for the SCSI Miniport Drivers:
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Disk
        - vname: TimeOutValue
        - vtype: REG_DWORD
        - vdata: 0x000000be
{% endif %}

{% if grains["os_family"] == "Windows" and grains["osrelease"] not in ["7"] -%}
Disable updating the LastAccessTime timestamp on the filesystems:
    cmd.run:
        - name: 'fsutil behavior set disablelastaccess 1'
{% endif %}
