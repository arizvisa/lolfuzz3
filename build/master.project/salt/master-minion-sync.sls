## Synchronize module fixes (minion)

include:
    - master-minion

Synchronize all modules for the minion:
    saltutil.sync_all:
        - refresh: true
        - saltenv: master
        - require:
            - sls: master-minion

{% if grains["saltversioninfo"][0] | int < 3000 -%}
Deploy the salt.utils.templates module directly into the master-minion's site-packages:
    file.managed:
        - name: {{ grains["saltpath"] }}/utils/templates.py
        - source: salt://_utils/templates.py
        - mode: 0644

Deploy the salt.utils.path module directly into the master-minion's site-packages:
    file.managed:
        - name: {{ grains["saltpath"] }}/utils/path.py
        - source: salt://_utils/path.py
        - mode: 0644
{% endif -%}
