include:
    {% if salt["grains.get"]("os_family") == "Windows" -%}
    - package.windows
    {% else -%}
    - package.linux
    {% endif %}
