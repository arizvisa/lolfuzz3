{% set Root = pillar["local"]["root"] %}

include:
    - stack
    - master-minion

## salt beacon configuration
Install a default salt-minion beacon highstate:
    file.managed:
        - template: jinja
        - source: salt://local-beacon/default-top-state
        - name: '{{ Root }}/etc/salt/minion.d/beacon.conf'
        - context:
            beacon:
                inotify:
                    - files:
                        '{{ Root }}{{ pillar["service"]["container"]["paths"]["build"] }}':
                            mask:
                                - create
                                - delete
                                - modify
                            recurse: true
                        '{{ Root }}{{ pillar["service"]["container"]["paths"]["image"] }}':
                            mask:
                                - create
                                - delete
                                - modify
                            recurse: true
                    - disable_during_state_run: true
                service:
                    - services:
                        {% for name in pillar["service"] %}
                        '{{ name }}':
                            onchangeonly: true
                        {% endfor %}
        - use:
            - Make salt-minion configuration directory
        - requires:
            - Make salt-minion configuration directory
