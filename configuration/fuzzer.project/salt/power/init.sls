include:
    {% if salt["grains.get"]("os_family") == "Windows" -%}
    - power-management.windows
    {% else -%}
    - power-management.linux
    {% endif %}
