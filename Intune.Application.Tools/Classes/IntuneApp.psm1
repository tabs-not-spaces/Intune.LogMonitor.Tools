class IntuneApp {
    $ApplicationId
    $Url
    $Key
    $IV
    $BinFileName
    $DownloadPath

    IntuneApp([string]$ApplicationId, [PSCustomObject]$contentInfo, [PSCustomObject]$decryptInfo, [system.io.FileInfo]$downloadPath) {
        $this.ApplicationId = $applicationId
        $this.Url = $contentInfo.UploadLocation
        $this.Key = $decryptInfo.EncryptionKey
        $this.IV = $decryptInfo.IV
        $this.BinFileName = $(Split-Path $this.Url -Leaf)
        $this.DownloadPath = "$downloadPath\$applicationId"
    }
}

class IntuneApps {
    [System.Collections.ArrayList]$applications
    IntuneApps() {
        $this.applications = [System.Collections.ArrayList]::new()
    }
    Add([string]$applicationId, [PSCustomObject]$contentInfo, [PSCustomObject]$decryptInfo, [system.io.FileInfo]$downloadPath) {
        if ($applicationId -notin $this.applications.ApplicationId) {
            $intuneApp = [IntuneApp]::new($applicationId, $contentInfo, $decryptInfo, $downloadPath)
            $this.applications.Add($intuneApp)
            New-Event -SourceIdentifier 'Intune.Application.Tools' -MessageData $intuneApp
        }
    }
}