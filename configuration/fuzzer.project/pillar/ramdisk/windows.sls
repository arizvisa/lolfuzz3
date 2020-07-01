Drivers:
    RamDisk:
        Path: C:/Drivers/RamDisk
        Timeout: 5
        Disks:
            - drive: R
              filesystem: ntfs
              size: 64
              label: Default RAM Disk

Source:
    SoftPerfect RAM Disk:
        name: ramdisk_setup.exe
        description: SoftPerfect RAM Disk
        version: 3.4.8
        documentation: https://www.majorgeeks.com/files/details/softperfect_ram_disk.html
        source: https://files1.majorgeeks.com/9c5c4f835ce02370704fa72f5c4d13903684b2be/system/ramdisk_setup.exe

    ImDisk Toolkit:
        name: ImDiskTk.zip
        description: ImDisk Toolkit
        version: 2.0.10.20200609
        documentation: https://sourceforge.net/projects/imdisk-toolkit/

        {% if grains["cpuarch"] == "x86" -%}
        source: https://downloads.sourceforge.net/project/imdisk-toolkit/20200609/ImDiskTk.zip
        {% elif grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" -%}
        source: https://downloads.sourceforge.net/project/imdisk-toolkit/20200609/ImDiskTk-x64.zip
        {% endif %}
