include:
    {% if salt["grains.get"]("os_family") == "Windows" -%}
    - audio.windows
    {% else -%}
    - audio.linux
    {% endif %}
