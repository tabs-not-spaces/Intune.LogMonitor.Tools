function Find-AppDataFromLog {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $false)]
        [System.Io.FileInfo]$IMEAgentLogFile = $(Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"),

        [parameter(Mandatory = $false)]
        [System.IO.FileInfo]$OutputFolder = "$env:temp",

        [parameter(Mandatory = $false)]
        [switch]$RunOnce
    )
    try {
        $stayInLoop = $true
        while ($stayInLoop) {
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
                        $script:intuneApplications.Add($responsePayload.ApplicationId, $contentInfo, $decryptInfo, $OutputFolder)
                    }
                }
            }
            $stayInLoop = $RunOnce
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