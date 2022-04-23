function Stop-IMELogMonitor {
    [cmdletbinding()]
    param (
        [switch]$ReturnApplicationMetadata
    )
    try {
        Set-IMELogLevel -LogLevel "Information"
        Get-Job -Name "IMELogMonitor" | Stop-Job
        $jobResults = Get-Job -Name "IMELogMonitor" | Receive-Job
        Get-Job -Name "IMELogMonitor" | Remove-Job
        return $($jobResults | ConvertFrom-Json -Depth 20)
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}