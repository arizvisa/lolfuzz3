Apply highstate to minion:
    runner.salt.cmd:
        - args:
            - fun: log.info
            - message: "Welcoming minion {{ data.id }} by synchronizing it with its highstate."

    local.state.apply:
        - tgt: {{ data.id }}

