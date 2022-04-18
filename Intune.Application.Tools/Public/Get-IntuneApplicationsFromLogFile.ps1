function Get-IntuneApplicationsFromLogFile {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $false)]
        [System.Io.FileInfo]$IMEAgentLogFile = $(Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"),

        [parameter(Mandatory = $false)]
        [System.IO.FileInfo]$OutputFolder = $env:temp
    )
    try {
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
    catch {
        $errorMsg = $_
    }
    finally {
        if ($errorMsg) {
            Write-Error $errorMsg -ErrorAction Stop
        }
        else {
            Write-Host "Applications downloaded and decrypted to $OutputFolder" -ForegroundColor Green
        }
    }
}