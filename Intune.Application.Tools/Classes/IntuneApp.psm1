class IntuneApp {
    $Url
    $Key
    $IV
    $BinFileName

    IntuneApp([PSCustomObject]$contentInfo, [PSCustomObject]$decryptInfo) {
        $this.Url = $contentInfo.UploadLocation
        $this.Key = $decryptInfo.EncryptionKey
        $this.IV = $decryptInfo.IV
        $this.BinFileName = $(Split-Path $this.Url -Leaf)
    }
}