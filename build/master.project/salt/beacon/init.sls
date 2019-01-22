{% set ContainerService = pillar['service']['container'] %}

include:
    - stack
    - minion

## salt beacon configuration
Install a default salt-minion beacon highstate:
    file.managed:
        - template: jinja
        - source: salt://beacon/default.top-state
        - name: /etc/salt/minion.d/beacon.conf
        - context:
            beacon:
                inotify:
                    - files:
                        {{ ContainerService.Path }}/build:
                            auto_add: true
                        {{ ContainerService.Path }}/image:
                            auto_add: true
                service:
                    - services:
                        {% for name in pillar['service'] %}
                        {{ name }}:
                            onchangeonly: true
                        {% endfor %}
        - use:
            - Make salt-minion configuration directory
        - requires:
            - Make salt-minion beacon directory
            - Make salt-minion configuration directory
