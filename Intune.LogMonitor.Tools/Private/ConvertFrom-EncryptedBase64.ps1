function ConvertFrom-EncryptedBase64 {
    [cmdletbinding()]
    param (
        [string]$B64String
    )
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    try {
        $content = [Convert]::FromBase64String($B64String)
        $envelopedCms = New-Object Security.Cryptography.Pkcs.EnvelopedCms
        $certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
        $envelopedCms.Decode($content)
        $envelopedCms.Decrypt($certCollection)
        
        $utf8content = [text.encoding]::UTF8.getstring($envelopedCms.ContentInfo.Content)
        return $utf8content
    }
    catch [System.Management.Automation.MethodInvocationException] {
        Write-Warning "You can't decrypt log files generated from a different device.."
        Write-Warning $_.Exception.Message
    }

}