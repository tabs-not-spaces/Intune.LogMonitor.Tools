function Initialize-IMEEventWatcher {
    [cmdletbinding()]
    param()
    Register-EngineEvent -SourceIdentifier "Intune.Application.Tools" -Action {
        $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
        $script:tick = [char]0x221a
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
        try {
            $app = $event.MessageData
            Write-Host "`nApplication found: " -NoNewline
            Write-Host "$($app.applicationId)" -ForegroundColor Green
            $appOutput = $app.DownloadPath
            Write-Host "Processing encrypted binaries: " -NoNewline
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
        }
        catch {
            $errorMsg = $_
        }
        finally {
            if ($errorMsg) {
                Write-Host "X" -ForegroundColor Red
                Write-Warning $errorMsg.Exception.Message
            }
            else {
                Write-Host $script:tick -ForegroundColor Green
                Write-Host "App payload decrypted to: " -NoNewline
                Write-Host "$appOutput`n" -ForegroundColor Green
                Write-Host "---`n"
            }
        }
    } | Out-Null
}