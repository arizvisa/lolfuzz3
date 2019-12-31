include:
    {% if salt["grains.get"]("os_family") == "Windows" -%}
    - power.windows
    {% else -%}
    - power.linux
    {% endif %}
