function Invoke-FileDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [string]$Path
    )

    Write-Verbose "URL set to ""$($Url)""."

    if (!($Path)) {
        Write-Verbose "Path parameter not set, parsing Url for filename."
        $URLParser = $Url | Select-String -Pattern ".*\:\/\/.*\/(.*\.{1}\w*).*" -List

        $Path = "./$($URLParser.Matches.Groups[1].Value)"
    }

    if (!(Test-Path $Path -ErrorAction SilentlyContinue)) {
        New-Item -Path $(Split-Path $Path -Parent) -ItemType Directory -Force | Out-Null
    }

    Write-Verbose "Path set to ""$($Path)""."

    #Load in the WebClient object.
    Write-Verbose "Loading in WebClient object."
    try {
        $Downloader = New-Object -TypeName System.Net.WebClient
    }
    catch [Exception] {
        Write-Error $_ -ErrorAction Stop
    }

    #Creating a temporary file.
    $TmpFile = New-TemporaryFile
    Write-Verbose "TmpFile set to ""$($TmpFile)""."

    try {
        #region download and monitor progress
        Write-Verbose "Starting download..."
        $FileDownload = $Downloader.DownloadFileTaskAsync($Url, $TmpFile)
        
        Write-Verbose "Registering the ""DownloadProgressChanged"" event handle from the WebClient object."
        Register-ObjectEvent -InputObject $Downloader -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged | Out-Null
        
        Start-Sleep -Seconds 3
        
        if ($FileDownload.IsFaulted) {
            Write-Verbose "An error occurred. Generating error."
            Write-Error $FileDownload.GetAwaiter().GetResult()
            break
        }
        
        while (!($FileDownload.IsCompleted)) {
            
            if ($FileDownload.IsFaulted) {
                Write-Verbose "An error occurred. Generating error."
                Write-Error $FileDownload.GetAwaiter().GetResult()
                break
            }
            
            $EventData = Get-Event -SourceIdentifier WebClient.DownloadProgressChanged | Select-Object -ExpandProperty "SourceEventArgs" -Last 1
            
            $ReceivedData = ($EventData | Select-Object -ExpandProperty "BytesReceived")
            $TotalToReceive = ($EventData | Select-Object -ExpandProperty "TotalBytesToReceive")
            $TotalPercent = $EventData | Select-Object -ExpandProperty "ProgressPercentage"
            
            Write-Progress -Activity "Downloading File" -Status "Percent Complete: $($TotalPercent)%" -CurrentOperation "Downloaded $(Convert-FileSize -bytes $ReceivedData) / $(Convert-FileSize -bytes $TotalToReceive)" -PercentComplete $TotalPercent
            #endregion
        }
    }
    catch [Exception] {
        #region Error handling
        $ErrorDetails = $_

        switch ($ErrorDetails.FullyQualifiedErrorId) {
            "ArgumentNullException" {
                Write-Error -Exception "ArgumentNullException" -ErrorId "ArgumentNullException" -Message "Either the Url or Path is null." -Category InvalidArgument -TargetObject $Downloader -ErrorAction Stop
            }
            "WebException" {
                Write-Error -Exception "WebException" -ErrorId "WebException" -Message "An error occurred while downloading the resource." -Category OperationTimeout -TargetObject $Downloader -ErrorAction Stop
            }
            "InvalidOperationException" {
                Write-Error -Exception "InvalidOperationException" -ErrorId "InvalidOperationException" -Message "The file at ""$($Path)"" is in use by another process." -Category WriteError -TargetObject $Path -ErrorAction Stop
            }
            Default {
                Write-Error $ErrorDetails -ErrorAction Stop
            }
        }
        #endregion
    }
    finally {
        #region Cleanup tasks
        Write-Verbose "Cleaning up..."
        Write-Progress -Activity "Downloading File" -Completed
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged

        if (($FileDownload.IsCompleted) -and !($FileDownload.IsFaulted)) {
            #If the download was finished without termination, then we move the file.
            Write-Verbose "Moved the downloaded file to ""$($Path)""."
            Move-Item -Path $TmpFile -Destination $Path -Force
        }
        else {
            #If the download was terminated, we remove the file.
            Write-Verbose "Cancelling the download and removing the tmp file."
            $Downloader.CancelAsync()
            Remove-Item -Path $TmpFile -Force
        }

        $Downloader.Dispose()
        #endregion
    }
}