{%- for tgt in data.tgt -%}
Log a new job message for {{ tgt }}:
    runner.salt.cmd:
        - args:
            - fun: log.info
            - message: "Job {{ data.jid }} was created for {{ tgt }} by {{ data.user }} using {{ data.fun }}."

{% endfor -%}
