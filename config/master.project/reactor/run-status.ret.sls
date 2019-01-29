Log a completed job runner message:
    runner.salt.cmd:
        - args:
            {% if data['success'] -%}
            - fun: log.info
            - message: "Completed (runner) job {{ data['jid'] }} using \"{{ data['fun'] }}\" ({{ data['fun_args'] | json | replace('"', '\\"') }}) successfully ({{ data['return'] | json | replace('"', '\\"') }})."
            {%- else %}
            - fun: log.error
            - message: "Completed (runner) job {{ data['jid'] }} using \"{{ data['fun'] }}}\" ({{ data['fun_args'] | json | replace('"', '\\"') }}) unsuccessfully ({{ data['return'] | json | replace('"', '\\"') }})."
            {%- endif %}

