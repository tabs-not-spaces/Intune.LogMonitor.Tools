function Start-IMEAppMonitor {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false)]
        [System.Io.FileInfo]$IMEAgentLogFile = $(Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"),

        [parameter(Mandatory = $false)]
        [System.IO.FileInfo]$OutputFolder = "$env:temp"
    )

    try {
        Set-IMELogLevel -LogLevel "Verbose"
        [IntuneApps]$script:intuneApplications = [IntuneApps]::new()
        Initialize-IMEEventWatcher

        Write-Host "Monitoring IME log for applications.." -ForegroundColor Yellow
        Write-Host "Press CTRL+C to cancel.." -ForegroundColor Black -BackgroundColor Yellow

        Find-AppDataFromLog -IMEAgentLogFile $IMEAgentLogFile -OutputFolder $OutputFolder
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    Finally {
        Write-Verbose "Shutting everything down.."
        Set-IMELogLevel -LogLevel "Information"
        Get-EventSubscriber -SourceIdentifier "IME.AppFound" | Unregister-Event
        Get-Job -Name "IME.AppFound" | Remove-Job
    }
}