Power-management package dependencies:
    pkg.installed:
        - pkgs:
            - {{ pillar["package"]["glib2"]["name"] }}: '{{ pillar["package"]["glib2"]["version"] }}'
            - {{ pillar["package"]["gnome-settings-daemon"]["name"] }}: '{{ pillar["package"]["gnome-settings-daemon"]["version"] }}'
            - {{ pillar["package"]["gsettings-desktop-schemas"]["name"] }}: '{{ pillar["package"]["gsettings-desktop-schemas"]["version"] }}'

{% for schema in pillar["power-management"]["gsetting"] -%}
{%- for key in pillar["power-management"]["gsetting"][schema] %}
Apply setting to gnome interface for root -- {{ schema }} {{ key }}:
    cmd.run:
        - name: 'dbus-launch gsettings set "{{ schema }}" "{{ key }}" "{{ pillar["power-management"]["gsetting"][schema][key] | lower }}"'
        - runas: root
        - require:
            - Power-management package dependencies

Apply setting to gnome interface for user -- {{ schema }} {{ key }}:
    cmd.run:
        - name: 'dbus-launch gsettings set "{{ schema }}" "{{ key }}" "{{ pillar["power-management"]["gsetting"][schema][key] | lower }}"'
        - runas: user
        - require:
            - Power-management package dependencies

{% endfor -%}
{%- endfor %}
