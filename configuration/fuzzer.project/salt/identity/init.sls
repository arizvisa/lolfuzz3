include:
    {% if salt["grains.get"]("os_family") == "Windows" -%}
    - identity.windows
    {% else -%}
    - identity.linux
    {% endif %}
