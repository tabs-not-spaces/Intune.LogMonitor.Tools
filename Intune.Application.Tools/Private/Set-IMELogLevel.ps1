#Requires -RunAsAdministrator
function Set-IMELogLevel {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $false)]
        [ValidateSet("Information", "Verbose")]
        [string]$LogLevel = "Information"
    )
    $imeConfigPath = "$(${env:ProgramFiles(x86)})\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe.config"

    try {
        [xml]$imeConfig = New-Object xml
        $imeConfig.Load($imeConfigPath)
        [string]$currentLogLevel = $imeConfig.configuration.'system.diagnostics'.sources.source.switchValue
        if (!($currentLogLevel -eq $LogLevel)) {
            Write-Verbose "Setting log level from $currentLogLevel to $LogLevel"
            $imeConfig.configuration.'system.diagnostics'.sources.source.switchValue = $LogLevel
            $imeConfig.Save($imeConfigPath)
            Restart-Service -Name IntuneManagementExtension
        }
        else {
            Write-Verbose "Log level is already set to $LogLevel. No changes have been applied."
        }
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}