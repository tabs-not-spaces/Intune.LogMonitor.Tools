function Get-AppDataFromLog {
    [cmdletbinding()]
    param (
        [System.IO.FileInfo]$IMEAgentLogFile = $(Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log")
    )
    try {
        $results = [IntuneApps]::new()
        $logData = Get-Content $IMEAgentLogFile
        $logMatches = Select-String -Path $IMEAgentLogFile -Pattern '\<\!\[LOG\[Response from Intune = {' -AllMatches
        $foundApps = foreach ($app in $logMatches) {
            $reply = "{$($logData[$app.LineNumber].ToString().TrimStart())}" | ConvertFrom-Json
            if ($reply.ResponseContentType -ne 'GetContentInfo') { continue }
            $responsePayload = $reply.ResponsePayload | ConvertFrom-Json
            $contentInfo = $responsePayload.ContentInfo | ConvertFrom-Json
            $decryptInfo = ConvertFrom-EncryptedBase64 -B64String ([xml]$responsePayload.DecryptInfo).EncryptedMessage.EncryptedContent | ConvertFrom-Json
            $results.Add($responsePayload.ApplicationId, $contentInfo, $decryptInfo)
        }
        if ($foundApps.count -gt 0) {
            Write-Host "Found $($foundApps.Count) applications in logfile.." -ForegroundColor Green
            $results.AddRange($foundApps)
            return $results.ToArray()
        }
        else {
            throw [System.Management.Automation.MethodInvocationException]::new("No application entries found in log file.")
        }
    }
    catch [System.Exception] {
        $errorDetails = $_
        switch  ($errorDetails.FullyQualifiedErrorId){
            "MethodInvocationException" {
                Write-Error -Exception "MethodInvocationException" -ErrorId "MethodInvocationException" -Message $errorDetails.Exception.Message -Category "InvalidResult" -TargetObject $foundApps -ErrorAction Stop
            }
            Default {
                Write-Error $errorDetails -ErrorAction Stop
            }
        }
    }
}