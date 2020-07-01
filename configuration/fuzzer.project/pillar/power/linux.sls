Package:
    glib2:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: glib2
        {% elif grains["os_family"] in ["Debian"] -%}
        name: libglib2.0-bin
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 2.48.2'

    gnome-settings-daemon:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: gnome-settings-daemon
        {% elif grains["os"] in ["Ubuntu"] -%}
        name: gnome-settings-daemon
        {% elif grains["os_family"] in ["Debian"] -%}
        name: gnome-settings-daemon-common
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 3.18.2'

    gsettings-desktop-schemas:
        {% if grains["os_family"] in ["RedHat"] -%}
        name: gsettings-desktop-schemas
        {% elif grains["os_family"] in ["Debian"] -%}
        name: gsettings-desktop-schemas
        {% else -%}
        name: '{{ "ERROR: unsupported os family {}".format(grains["os_family"]) }}'
        {% endif -%}
        version: '>= 3.18.1'

power-management:
    gsetting:
        org.gnome.desktop.session:
            idle-delay: 0

        org.gnome.desktop.screensaver:
            lock-enabled: false
            logout-enabled: false
            logout-delay: 0

        org.gnome.settings-daemon.plugins.power:
            idle-dim: false
            power-button-action: hibernate

            sleep-inactive-ac-type: nothing
            sleep-inactive-ac-timeout: 0
            sleep-inactive-battery-type: nothing
            sleep-inactive-battery-timeout: 0
