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
                        {{ pillar['service']['container']['path']}}/build:
                            auto_add: true
                        {{ pillar['service']['container']['path']}}/image:
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
            - Make salt-minion configuration directory
