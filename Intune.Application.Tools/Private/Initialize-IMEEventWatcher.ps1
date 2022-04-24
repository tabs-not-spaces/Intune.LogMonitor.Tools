function Initialize-IMEEventWatcher {
    [cmdletbinding()]
    param()
    Register-EngineEvent -SourceIdentifier "Intune.Application.Tools" -Action {
        $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
        [system.uri]$script:Alert = "$script:ModuleRoot\Media\Alert.mp3"

        #region Get public and private function definition files.
        $Private = @(Get-ChildItem -Path $script:ModuleRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
        #endregion
        #region Dot source the files
        foreach ($import in $Private) {
            try {
                . $import.FullName
            }
            catch {
                Write-Error -Message "Failed to import function $($import.FullName): $_"
            }
        }
        $app = $event.MessageData
        Write-Host "Processing found app: $($app.applicationId)"
        $appOutput = $app.DownloadPath
        Write-Host "Will download media and dump to $appOutput.."
        Start-GuilfoylAlert
        $ifdParams = @{
            Url  = $app.Url
            Path = "$appOutput\$($app.BinFileName)"
        }
        Invoke-FileDownload @ifdParams
        $eiParams = @{
            InputFile    = "$appOutput\$($app.BinFileName)"
            OutputFolder = $appOutput
            EncKey       = $app.Key
            EncIV        = $app.IV
        }
        Expand-Intunewin @eiParams
    } | Out-Null
}