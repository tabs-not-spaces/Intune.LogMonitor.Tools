function Start-IMELogMonitor {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $false)]
        [System.Io.FileInfo]$IMEAgentLogFile = $(Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"),

        [parameter(Mandatory = $false)]
        [System.IO.FileInfo]$OutputFolder = $env:temp
    )
    $moduleRoot = Split-Path $PSScriptRoot -Parent
    $init = [scriptblock]::Create('
        using module "{0}\Classes\IntuneApp.psm1"
        $privateFunctions = @(Get-ChildItem "{0}\private\*.ps1" -ErrorAction SilentlyContinue)
        foreach ($import in $privateFunctions) {
            try {
                . $import.fullName
            }
            catch {
                Write-Error -Message "Failed to import function $($import.FullName): $_"
            }
        }
    ' -f $moduleRoot)
    $logWatcher = {
        param($IMEAgentLogFile)
        Register-EngineEvent -SourceIdentifier "Intune.Application.Tools" -Action {
            #region Process the found applications.
            $app = $event.MessageData
            "`nFound application with appId: $($app.ApplicationId)" | Out-File D:\bin\logfile.txt -Append
            "URL: $($app.Url)" | Out-File D:\bin\logfile.txt -Append
            "Key: $($app.Key)" | Out-File D:\bin\logfile.txt -Append
            "IV: $($app.IV)" | Out-File D:\bin\logfile.txt -Append
            "BinFileName: $($app.BinFileName)" | Out-File D:\bin\logfile.txt -Append
            #endregion
        } | Out-Null
        [IntuneApps]$intuneApplications = [IntuneApps]::new()
         Get-Content $IMEAgentLogFile -Wait | Select-String -Pattern '\<\!\[LOG\[Response from Intune = {' -AllMatches  | ForEach-Object {
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
    Start-Job -Name "IMELogMonitor" -ScriptBlock $logWatcher -InitializationScript $init -ArgumentList $IMEAgentLogFile
}