# This pillar contains a list of updates that need to be manually installed in
# order for the regular windows update system to work.

Updates:

    ## Windows Update Agent 7.6.7600.320

    # The following urls were found at the following url:
    # https://support.microsoft.com/en-us/help/949104/how-to-update-the-windows-update-agent-to-the-latest-version 

{%- if grains["osrelease"] == "7" or grains["osrelease"] == "2008ServerR2" -%}
    {%- if grains["cpuarch"] == "x86" %}
    - name: windowsupdateagent-7.6-x86.exe
      source: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-x86.exe
      hash: 9fc6856827123d0391a2c7451ccb1cbf93261442252dd87819ad5b8db72b0ec0
    {%- elif grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" %}
    - name: windowsupdateagent-7.6-x64.exe
      source: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-x64.exe
      hash: d82a85e4874fbee6cb70479a5e146bb373a82cf8d898c95a600358b6e1933c24
    {%- elif grains["cpuarch"] == "IA64" %}
    - name: windowsupdateagent-7.6-ia64.exe
      source: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-ia64.exe
      hash: c3645037ed96bf9ccb75d1ef40a8453382e03a06f2c44d97c97bb4e5ccf49097
    {%- endif %}
{% endif -%}
