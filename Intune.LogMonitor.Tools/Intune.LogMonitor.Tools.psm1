using module 'classes\IntuneApp.psm1'

$script:ModuleRoot = $PSScriptRoot
$script:Alert = "$script:ModuleRoot\Media\Alert.mp3"

#region Get public and private function definition files.
$Public  = @(Get-ChildItem -Path $script:ModuleRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $script:ModuleRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
#endregion
#region Dot source the files
foreach ($import in @($Public + $Private))
{
    try
    {
        . $import.FullName
    }
    catch
    {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}
#endregion