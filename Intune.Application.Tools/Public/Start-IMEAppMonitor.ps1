function Start-IMEAppMonitor {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $false)]
        [System.Io.FileInfo]$IMEAgentLogFile = $(Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"),

        [parameter(Mandatory = $false)]
        [System.IO.FileInfo]$OutputFolder = "D:\temp"
    )

    try {
        Set-IMELogLevel -LogLevel "Verbose"
        [IntuneApps]$intuneApplications = [IntuneApps]::new()
        Initialize-IMEEventWatcher

        Write-Host "Monitoring IME log for applications.." -ForegroundColor Yellow
        Write-Host "Press CTRL+C to cancel.." -ForegroundColor Black -BackgroundColor Yellow

        while ($true) {
            $logData = Get-Content $IMEAgentLogFile
            $filteredLog = $logData |
            Select-String -Pattern '\<\!\[LOG\[Response from Intune = {' -AllMatches
            if ($filteredLog) {
                foreach ($log in $filteredLog) {
                    $reply = "{$($logData[$log.LineNumber].ToString().TrimStart())}" | ConvertFrom-Json
                    if ($reply.ResponseContentType -eq 'GetContentInfo') { 
                        $responsePayload = $reply.ResponsePayload | ConvertFrom-Json
                        $contentInfo = $responsePayload.ContentInfo | ConvertFrom-Json
                        $decryptInfo = ConvertFrom-EncryptedBase64 -B64String ([xml]$responsePayload.DecryptInfo).EncryptedMessage.EncryptedContent | ConvertFrom-Json
                        $intuneApplications.Add($responsePayload.ApplicationId, $contentInfo, $decryptInfo, $OutputFolder)
                    }
                }
            }
        }
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    Finally {
        #Set-IMELogLevel -LogLevel "Information"
        Write-Verbose "This is where we will return the loglevel back to info.."
        Get-EventSubscriber -SourceIdentifier "Intune.Application.Tools" | Unregister-Event
        Get-Job -Name "Intune.Application.Tools" | Remove-Job
    }
}