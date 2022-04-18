class IntuneApp {
    $ApplicationId
    $Url
    $Key
    $IV
    $BinFileName

    IntuneApp([string]$ApplicationId, [PSCustomObject]$contentInfo, [PSCustomObject]$decryptInfo) {
        $this.ApplicationId = $applicationId
        $this.Url = $contentInfo.UploadLocation
        $this.Key = $decryptInfo.EncryptionKey
        $this.IV = $decryptInfo.IV
        $this.BinFileName = $(Split-Path $this.Url -Leaf)
    }
}

class IntuneApps {
    [System.Collections.ArrayList]$applications
    IntuneApps() {
        $this.applications = [System.Collections.ArrayList]::new()
    }
    Add([string]$applicationId, [PSCustomObject]$contentInfo, [PSCustomObject]$decryptInfo) {
        if ($applicationId -notin $this.applications.ApplicationId) {
            $intuneApp = [IntuneApp]::new($applicationId, $contentInfo, $decryptInfo)
            $this.applications.Add($intuneApp)
            New-Event -SourceIdentifier 'Intune.Application.Tools' -MessageData $intuneApp
        }
    }
}