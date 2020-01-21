Ensure sshd is running:
    service.running:
        - name: sshd
        - enable: true

Everything is up to date:
    pkg.uptodate:
        - name: package updates
        {% if grains["os_family"] in ["RedHat"] -%}
        - exclude: 'kernel*'
        {% endif -%}
        - refresh: true

