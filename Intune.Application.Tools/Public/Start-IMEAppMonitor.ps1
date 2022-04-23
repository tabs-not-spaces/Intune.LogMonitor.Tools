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
        Register-EngineEvent -SourceIdentifier "Intune.Application.Tools" -Action {
            Start-GuilfoylAlert
            $app = $event.MessageData
            Write-Host "Processing found app: $($app.applicationId)"
            $appOutput = $app.DownloadPath
            Write-Host "Will download media and dump to $appOutput.."
            $ifdParams = @{
                Url = $app.Url
                Path = "$appOutput\$($app.BinFileName)"
            }
            Invoke-FileDownload @ifdParams -Verbose
            $eiParams = @{
                InputFile    = "$appOutput\$($app.BinFileName)"
                OutputFolder = $appOutput
                EncKey       = $app.Key
                EncIV        = $app.IV
            }
            Expand-Intunewin @eiParams -Verbose
        } | Out-Null

        Get-Content $IMEAgentLogFile -Wait |
        Select-String -Pattern '\<\!\[LOG\[Response from Intune = {' -AllMatches |
        Where-Object { $_ -ne $null } |
        ForEach-Object -ErrorAction SilentlyContinue {
            $logData = Get-Content $IMEAgentLogFile
            $app = $_
            $reply = "{$($logData[$app.LineNumber].ToString().TrimStart())}" | ConvertFrom-Json
            if ($reply.ResponseContentType -eq 'GetContentInfo') { 
                $responsePayload = $reply.ResponsePayload | ConvertFrom-Json
                $contentInfo = $responsePayload.ContentInfo | ConvertFrom-Json
                $decryptInfo = ConvertFrom-EncryptedBase64 -B64String ([xml]$responsePayload.DecryptInfo).EncryptedMessage.EncryptedContent | ConvertFrom-Json
                $intuneApplications.Add($responsePayload.ApplicationId, $contentInfo, $decryptInfo, $OutputFolder)
            }
        }
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    Finally {
        Set-IMELogLevel -LogLevel "Information"
        Get-EventSubscriber -SourceIdentifier "Intune.Application.Tools" | Unregister-Event
    }
}