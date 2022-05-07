function Convert-FileSize {
    [cmdletbinding()]
    [OutputType([System.String])]
    param(
        [double]$bytes
    )
    try {
        switch ($bytes) {
            {$_ -lt 1MB} {
                return "$([Math]::Round($bytes / 1KB, 2)) KB"
            }
            {$_ -gt 1MB -and $_ -lt 1GB} {
                return "$([Math]::Round($bytes / 1MB, 2)) MB"
            }
            {$_ -gt 1GB -and $_ -lt 1TB} {
                return "$([Math]::Round($bytes / 1GB, 2)) GB"
            }
        }
    }
    catch {
        Write-Error $_ -ErrorAction Stop
    }
}