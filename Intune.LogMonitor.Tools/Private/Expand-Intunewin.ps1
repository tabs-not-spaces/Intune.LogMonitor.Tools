function Expand-Intunewin {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$InputFile,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$OutputFolder,

        [Parameter(Mandatory = $true)]
        [string]$EncKey,

        [Parameter(Mandatory = $true)]
        [string]$EncIV
    )
    try {
        #region generate crypto and decrypt objects
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = [system.convert]::FromBase64String($EncKey)
        $aes.IV = [system.convert]::FromBase64String($EncIv)
        $decryptor = $aes.CreateDecryptor($aes.Key, $aes.IV)
        #endregion
        #region decrypt the target file
        $file = Get-Item $InputFile
        $destinationFile = "$(Split-Path -Path $file.FullName -Parent)\$($file.name -replace '.bin').zip"
        $fileStreamReader = New-Object System.IO.FileStream($File.FullName, [System.IO.FileMode]::Open)
        $fileStreamWriter = New-Object System.IO.FileStream($destinationFile, [System.IO.FileMode]::Create)
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($fileStreamWriter, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
        $fileStreamReader.CopyTo($cryptoStream)
        Expand-7Zip -ArchiveFileName $destinationFile -TargetPath "$OutputFolder\$($file.name -replace '.bin')"
        #endregion
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    finally {
        #region dispose of all open objects
        Write-Verbose "Cleaning everything up.."
        $cryptoStream.FlushFinalBlock()
        $cryptoStream.Dispose()
        $fileStreamReader.Dispose()
        $fileStreamWriter.Dispose()
        $aes.Dispose()
        #endregion
    }
}