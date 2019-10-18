{%- for minion in data['minions'] -%}
Log a new job message for {{ minion }}:
    runner.salt.cmd:
        - args:
            - fun: log.info
            - message: "New job {{ data['jid'] }} using \"{{ data['fun'] }}\" ({{ data['arg'] | json | replace('"', '\\"') }}) created for {{ minion }} by {{ data['user'] }} via \"{{ data['tgt'] }}\" ({{ data['tgt_type'] }})."

{% endfor -%}
