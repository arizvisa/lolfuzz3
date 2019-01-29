Log a new job runner message:
    runner.salt.cmd:
        - args:
            - fun: log.info
            - message: "New (runner) job {{ data['jid'] }} using \"{{ data['fun'] }}\" ({{ data['fun_args'] | json | replace('"', '\\"') }}) created by {{ data['user'] }}."

