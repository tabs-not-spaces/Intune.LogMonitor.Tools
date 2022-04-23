function Start-IMELogMonitor {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $false)]
        [System.Io.FileInfo]$IMEAgentLogFile = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log",

        [parameter(Mandatory = $false)]
        [System.IO.FileInfo]$OutputFolder = $env:temp
    )
    #region Initialization script
    $initScriptBlock = @"
using module "$($script:ModuleRoot)\Classes\IntuneApp.psm1"
`$privateFunctions = @(Get-ChildItem "$($script:ModuleRoot)\private\*.ps1" -ErrorAction SilentlyContinue)
foreach (`$import in `$privateFunctions) {
    try {
        . `$import.fullName
    }
    catch {
        Write-Error -Message "Failed to import function `$(`$import.FullName): $_"
    }
}
"@
    $init = [scriptblock]::Create($initScriptBlock)
    #endregion
    #region IMELogMonitor scriptblock
    $logWatcher = {
        param(
            [string]$IMEAgentLogFile, 
            [string]$OutputFolder
        )
        try {
            Register-EngineEvent -SourceIdentifier "Intune.Application.Tools" -Action {
                #region Process the found applications.
                Start-Transcript -Path "D:\bin\logfile.txt" -Force
                $app = $event.MessageData
                Write-Host "app found. $($app.applicationId)"
                $appOutput = "$OutputFolder\$($app.ApplicationId)"
                Invoke-FileDownload -Url $($app.Url) -Path "$appOutput\$($app.BinFileName)"
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
        finally {
            $intuneApplications.applications | ConvertTo-Json -Depth 20
        }
    }
    #endregion
    
    Start-Job -Name "IMELogMonitor" -ScriptBlock $logWatcher -InitializationScript $init -ArgumentList $IMEAgentLogFile.FullName, $OutputFolder.FullName
}