Log a completed job message:
    runner.salt.cmd:
        - args:
            {% if data['success'] -%}
            - fun: log.info
            - message: "Completed job {{ data['jid'] }} using \"{{ data['fun'] }}\" ({{ data['fun_args'] | json | replace('"', '\\"') }}) on {{ data['id'] }} successfully ({{ data['retcode'] if 'retcode' in data else data['return'] }})."
            {%- else %}
            - fun: log.error
            - message: "Completed job {{ data['jid'] }} using \"{{ data['fun'] }}\" ({{ data['fun_args'] | json | replace('"', '\\"') }}) on {{ data['id'] }} unsuccessfully ({{ data['retcode'] if 'retcode' in data else data['return'] }})."
            {%- endif %}
