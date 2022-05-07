#Requires -RunAsAdministrator
function Set-IMELogLevel {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory = $false)]
        [ValidateSet("Information", "Verbose")]
        [string]$LogLevel = "Information"
    )
    $imeConfigPath = "$(${env:ProgramFiles(x86)})\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe.config"

    try {
        [string]$currentLogLevel = Get-IMELogLevel
        if (!($currentLogLevel -eq $LogLevel)) {
            Write-Verbose "Setting log level from $currentLogLevel to $LogLevel"
            [xml]$imeConfig = New-Object xml
            $imeConfig.Load($imeConfigPath)
            $imeConfig.configuration.'system.diagnostics'.sources.source.switchValue = $LogLevel
            $imeConfig.Save($imeConfigPath)
            Write-Verbose "Restarting IME service.."
            Restart-Service -Name IntuneManagementExtension | Out-Null
        }
        else {
            Write-Verbose "Log level is already set to $LogLevel. No changes have been applied."
        }
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}