function Get-IMELogLevel {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $false)]
        [System.IO.FileInfo]$IWAConfigFile = "$(${env:ProgramFiles(x86)})\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe.config"
    )

    try {
        [xml]$imeConfig = New-Object xml
        $imeConfig.Load($IWAConfigFile)
        return $imeConfig.configuration.'system.diagnostics'.sources.source.switchValue
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}