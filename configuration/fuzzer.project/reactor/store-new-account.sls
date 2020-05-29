{% set pillar = salt.saltutil.runner('pillar.show_pillar', kwarg={"minion": opts.master_id}) %}

(master) Create a new account for the client:
    local.state.apply:
        - tgt: 'role:master'
        - tgt_type: grain
        - args:
            - mods: store.new-account
            - saltenv: base
            - pillarenv: base
            - pillar:
                accessKey: {{ data.id }}
                secretKey: {{ pillar["configuration"]["name"] }}
                groupName: minion
