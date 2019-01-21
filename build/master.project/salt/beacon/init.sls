include:
    - stack
    - minion

## salt beacon configuration
Install a default salt-minion beacon highstate:
    file.managed:
        - template: jinja
        - source: salt://beacon/default.top-state
        - name: /etc/salt/minion.d/beacon.conf
        - defaults:
            beacon:
                inotify:
                    - files:
                        {{ pillar['service']['container']['Path'] }}/build:
                            auto_add: true
                        {{ pillar['service']['container']['Path'] }}/image:
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
