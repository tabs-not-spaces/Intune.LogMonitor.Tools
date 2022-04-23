function Get-IntuneApplicationsFromLogFile {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $false)]
        [System.Io.FileInfo]$IMEAgentLogFile = $(Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"),

        [parameter(Mandatory = $false)]
        [System.IO.FileInfo]$OutputFolder = $env:temp,

        [switch]$RunAsBackgroundTask
    )
    try {
        Set-IMELogLevel -LogLevel "Verbose"
        if ($RunAsBackgroundTask) {
            Register-EngineEvent -SourceIdentifier "Intune.Application.Tools" -Action {
                #region Process the found applications.
                Start-Transcript -Path "D:\bin\logfile.txt" -Force
                $app = $event.MessageData
                Write-Host "Processing found app: $($app.applicationId)"
                $appOutput = "$($OutputFolder.FullName)\$($app.ApplicationId)"
                Write-Host "Will download media and dump to $appOutput.."
                Invoke-FileDownload -Url $($app.Url) -Path "$appOutput\$($app.BinFileName)" -Verbose
                Expand-Intunewin -InputFile "$appOutput\$($app.BinFileName)" -OutputFolder $appOutput -EncKey $app.Key -EncIV $app.IV -Verbose
                Stop-Transcript
                #endregion
            } | Out-Null
            [IntuneApps]$intuneApplications = [IntuneApps]::new()
            Get-Content $IMEAgentLogFile -Wait | 
            Select-String -Pattern '\<\!\[LOG\[Response from Intune = {' -AllMatches | 
            Where-Object { $_ -ne $null } |
            ForEach-Object -ErrorAction SilentlyContinue {
                #if ($(Get-IMELogLevel) -eq 'Information') { Continue }
                $logData = Get-Content $IMEAgentLogFile
                $app = $_
                $reply = "{$($logData[$app.LineNumber].ToString().TrimStart())}" | ConvertFrom-Json
                if ($reply.ResponseContentType -eq 'GetContentInfo') { 
                    $responsePayload = $reply.ResponsePayload | ConvertFrom-Json
                    $contentInfo = $responsePayload.ContentInfo | ConvertFrom-Json
                    $decryptInfo = ConvertFrom-EncryptedBase64 -B64String ([xml]$responsePayload.DecryptInfo).EncryptedMessage.EncryptedContent | ConvertFrom-Json
                    $intuneApplications.Add($responsePayload.ApplicationId, $contentInfo, $decryptInfo)
                }
            }
        }
        else {
            [IntuneApps]$foundApps = [IntuneApps]::New()
            if (!(Test-Path $OutputFolder -ErrorAction SilentlyContinue)) {
                New-Item $OutputFolder -ItemType Directory -Force | Out-Null
            }
            Register-EngineEvent -SourceIdentifier 'Intune.Application.Tools' -Action {
                Write-Host "New application found.. $($Event.MessageData.ApplicationId)"
            }
            $foundApps = Get-AppDataFromLog -IMEAgentLogFile $IMEAgentLogFile
            foreach ($app in $foundApps) {
                #region Download each app detected from log fine
                Write-Host "`nDownloading $($app.BinFileName).." -ForegroundColor Cyan
                Invoke-FileDownload -Url $app.Url -Path "$OutputFolder\$($app.BinFileName)"
                #endregion
                #region Decrypt and expand each app
                Write-Host "Expanding $($app.BinFileName).." -ForegroundColor Cyan
                Expand-Intunewin -InputFile "$OutputFolder\$($app.BinFileName)" -OutputFolder $OutputFolder -EncKey $app.Key -EncIV $app.IV
                #endregion
            }
        }
    }
    catch {
        $errorMsg = $_
    }
    finally {
        if ($errorMsg) {
            Write-Error $errorMsg -ErrorAction Stop
        }
        else {
            if (!$RunAsBackgroundTask) {
                Write-Host "Applications downloaded and decrypted to $OutputFolder" -ForegroundColor Green
            }
        }
    }
}