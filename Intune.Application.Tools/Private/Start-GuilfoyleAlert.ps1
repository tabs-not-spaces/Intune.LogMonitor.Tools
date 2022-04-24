function Start-GuilfoylAlert {
    [cmdletbinding()]
    param ()
    try {
        Add-Type -AssemblyName PresentationCore
        $mp = New-Object System.Windows.Media.MediaPlayer
        $mp.Open($script:Alert)
        $mp.Volume = 1
        $mp.Play()
        Start-Sleep -Milliseconds 2900
        $mp.Stop()
        $mp.Close()

    }
    catch {
        Write-Warning $_.Exception.Message
    }
}