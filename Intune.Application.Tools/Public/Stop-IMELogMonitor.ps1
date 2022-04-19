function Stop-IMELogMonitor {
    [cmdletbinding()]
    param ()
    try {
        Get-Job -Name "IMELogMonitor" | Stop-Job
        Get-Job -Name "IMELogMonitor" | Remove-Job
        Set-IMELogLevel -LogLevel "Information"
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}