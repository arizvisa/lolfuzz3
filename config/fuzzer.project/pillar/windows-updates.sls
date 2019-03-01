# This pillar contains a list of updates that need to be manually installed in
# order for the regular windows update system to work.

Updates:

    ## Windows Update Agent 7.6.7600.256

    # The following urls were found at the following url:
    # https://support.microsoft.com/en-us/help/949104/how-to-update-the-windows-update-agent-to-the-latest-version 

    {% if grains["osrelease"] == "7" and grains["cpuarch"] == "x86" -%}
    - windowsupdateagent-7.6-x86.exe: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-x86.exe 
    {% elif grains["osrelease"] == "7" and ( grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" ) -%}
    - windowsupdateagent-7.6-x64.exe: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-x64.exe
    {% elif grains["osrelease"] == "2008ServerR2" and grains["cpuarch"] == "x86" -%}
    - windowsupdateagent-7.6-x86.exe: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-x86.exe
    {% elif grains["osrelease"] == "2008ServerR2" and ( grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" ) -%}
    - windowsupdateagent-7.6-x64.exe: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-x64.exe
    {% elif grains["osrelease"] == "2008ServerR2" and grains["cpuarch"] == "IA64" -%}
    - windowsupdateagent-7.6-ia64.exe: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-ia64.exe
    {% else -%}
    []
    {% endif -%}
