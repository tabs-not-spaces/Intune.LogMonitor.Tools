function Start-GuilfoylAlert {
    [cmdletbinding()]
    param ()
    try {
        Add-Type -AssemblyName PresentationCore
        $mp = New-Object System.Windows.Media.MediaPlayer
        $mp.Open($script:Alert)
        $mp.Volume = 1
        $mp.Play()
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}