{% if "cmd" in data and data["cmd"] == "_minion_event" %}
Log a message on the master:
    runner.salt.cmd:
        - args:
            - fun: log.{{ data['data'].level }}
            - message: {{ ("Message from " + data.id + ": " + data['data'].message) | yaml_dquote }}
{% elif "level" in data and "message" in data and "id" in data %}
Log a message on the master:
    runner.salt.cmd:
        - args:
            - fun: log.{{ data['level'] }}
            - message: {{ ("Message from " + data['id'] + ": " + data['message']) | yaml_dquote }}
{% else %}
Log an error message on the master:
    runner.salt.cmd:
        - args:
            - fun: log.error
            - message: {{ ("Log event was fired with unknown format for data: " + (data | pprint)) | yaml_dquote }}
{% endif %}

