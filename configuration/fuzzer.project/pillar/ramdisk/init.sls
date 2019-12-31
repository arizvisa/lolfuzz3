include:
    {% if salt["grains.get"]("os_family") == "Windows" -%}
    - ramdisk.windows
    {% else -%}
    - ramdisk.linux
    {% endif %}
