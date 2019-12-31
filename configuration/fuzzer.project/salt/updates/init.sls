include:
    {% if salt["grains.get"]("os_family") == "Windows" -%}
    - updates.windows
    {% else -%}
    - updates.linux
    {% endif %}
