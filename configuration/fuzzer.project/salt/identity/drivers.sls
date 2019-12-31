## (Service) Windows Defender
Add the drivers path to the exclusions for Windows Defender:
    {% if grains["osrelease"] in ("7", "8", "8.1") %}
    reg.present:
        - name: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths
        - vname: {{ pillar["Drivers"]["Path"] | replace("/", "\\") | yaml_dquote }}
        - vtype: REG_DWORD
        - vdata: 0x00000000
    {% else %}
    cmd.run:
        - name: Add-MpPreference -ExclusionPath "{{ pillar["Drivers"]["Path"] | replace("/", "\\") }}"
        - shell: powershell
    {% endif %}

## Powershell
Set Powershell Execution Policy:
    cmd.run:
        - name: 'powershell.exe -command Set-ExecutionPolicy Unrestricted'

Create the base driver directory:
    file.directory:
        - name: {{ pillar["Drivers"]["Path"] }}
        - makedirs: true
        - require:
            - Add the drivers path to the exclusions for Windows Defender

Make PowerShell driver directory:
    file.directory:
        - name: {{ pillar["Drivers"]["PowerShell"]["Path"] }}
        - makedirs: true
        - require:
            - Create the base driver directory

Extract PowerShell DeviceManagement module on target:
    archive.extracted:
        - name: {{ pillar["Drivers"]["PowerShell"]["Path"] }}
        - source: salt://identity/DeviceManagement.zip
        - archive_format: zip
        - enforce_toplevel: false
        - require:
            - Make PowerShell driver directory

## Driver tools
Make driver tools directory:
    file.directory:
        - name: {{ pillar["Drivers"]["Tools"] }}
        - makedirs: true
        - require:
            - Create the base driver directory

Install device finder tool on target:
    file.managed:
        - name: {{ pillar["Drivers"]["Tools"] }}/Find-Device.ps1
        - contents: |
            param (
                [Parameter(Mandatory=$true)][string]$Id
            )
            Import-Module "{{ pillar["Drivers"]["PowerShell"]["Path"] }}/Release/DeviceManagement.psd1"
            $devices = Get-Device | Where-Object { $Id -In $_.HardwareIDs }
            if ($devices.Length -gt 0) {
                Exit 1
            }
        - require:
            - Make driver tools directory
            - Extract PowerShell DeviceManagement module on target
            - Set Powershell Execution Policy

Install certificate extraction tool on target:
    file.managed:
        - name: {{ pillar["Drivers"]["Tools"] }}/Extract-Certificate.ps1
        - contents: |
            param (
                [Parameter(Mandatory=$true)][string]$Source,
                [Parameter(Mandatory=$true)][string]$Output
            )
            $sig = Get-AuthenticodeSignature $Source
            $cert = $sig.SignerCertificate
            $data = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
            [System.IO.File]::WriteAllBytes($Output, $data)
        - require:
            - Make driver tools directory
            - Set Powershell Execution Policy

Install certificate import tool on target:
    file.managed:
        - name: {{ pillar["Drivers"]["Tools"] }}/Trust-Certificate.ps1
        - contents: |
            param (
                [Parameter(Mandatory=$true)][string]$Certificate
            )
            $contents = Get-item $Certificate
            $x509 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $x509.Import($contents)

            $StoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]"LocalMachine"
            $StoreName = [System.Security.Cryptography.X509Certificates.StoreName]"TrustedPublisher"

            $Store = New-Object System.Security.Cryptography.X509Certificates.X509Store("$StoreName",$StoreLocation)
            $Store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]"ReadWrite")

            $Store.Add($x509)
            if ($?) {
                $Store.Close()
                Exit 0
            }
            $Store.Close()
            Exit 1
        - require:
            - Make driver tools directory
            - Set Powershell Execution Policy
