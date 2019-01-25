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
                            mask:
                                - create
                                - delete
                                - modify
                            recurse: true
                        {{ pillar['service']['container']['path']}}/image:
                            mask:
                                - create
                                - delete
                                - modify
                            recurse: true
                    - disable_during_state_run: true
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
