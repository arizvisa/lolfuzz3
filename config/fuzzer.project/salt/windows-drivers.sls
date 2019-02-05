Make PowerShell driver directory:
    file.directory:
        - name: {{ pillar["Drivers"]["PowerShell"]["Path"] }}
        - makedirs: true

Extract PowerShell DeviceManagement module on target:
    archive.extracted:
        - name: {{ pillar["Drivers"]["PowerShell"]["Path"] }}
        - source: salt://drivers/DeviceManagement.zip
        - archive_format: zip
        - enforce_toplevel: false
        - require:
            - Make PowerShell driver directory

Make driver tools directory:
    file.directory:
        - name: {{ pillar["Drivers"]["Tools"] }}
        - makedirs: true

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

Install certificate import tool on target:
    file.managed:
        - name: {{ pillar["Drivers"]["Tools"] }}/Trust-Certificate.ps1
        - contents: |
            param (
                [Parameter(Mandatory=$true)][string]$Certificate
            )
            Import-Certificate -CertStoreLocation cert:/LocalMachine/TrustedPublisher -File $Certificate
            if ($?) {
                Exit 0
            }
            Exit 1
        - require:
            - Make driver tools directory
