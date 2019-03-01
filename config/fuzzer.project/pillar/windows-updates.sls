# This pillar contains a list of updates that need to be manually installed in
# order for the regular windows update system to work.

# Set the architecture as determined by Python to the syntax that the Windows Update Agent uses
{% set architecture = "x64" if grains["cpuarch"] == "AMD64" or grains["cpuarch"] == "x86_64" else "ia64" if grains["cpuarch"] == "IA64" else grains["cpuarch"] %}

Updates:

    ## Windows Update Agent 7.6.7600.320

    # The following urls were found at the following url:
    # https://support.microsoft.com/en-us/help/949104/how-to-update-the-windows-update-agent-to-the-latest-version 

    {% if grains["osrelease"] == "7" or grains["osrelease"] == "2008ServerR2" -%}
    - windowsupdateagent-7.6-{{ architecture }}.exe: http://download.windowsupdate.com/windowsupdate/redist/standalone/7.6.7600.320/windowsupdateagent-7.6-{{ architecture }}.exe
    {% else -%}
    []
    {% endif -%}
