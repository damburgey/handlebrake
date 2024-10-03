[CmdletBinding()]Param(
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("hb")][string] $HandBrakeCLI="C:\Program Files\HandbrakeCLI\HandBrakeCLI.exe", # Set the path to HandBrakeCLI.exe
    [Parameter(Mandatory=$true,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("s")][string] $Source, # Specify either an individual file, or a folder containing many files
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("se")][string] $SourceExtensions="*.mkv", # Source file .extensions to include
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("si")][array] $SourceIgnore=@('MeGusta','x265','h265','Vault42'), # Source file EXCLUSIONs based on a search strings to filter out of the source file names
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("dfi")][string] $DestinationFile,  # Use only when specifing a single source file, and you want to direct the exact file output path/name
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("dfo")][string] $DestinationFolder, # Use when you want to specify a different output folder than the source folder, but use the same file names
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("p")][string] $Preset="H.265 NVENC 1080p", # Use the built in preset of H.265 NVENC 1080p
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("e")][string] $Encoder="nvenc_h265", # Use Nvidia GPU encoding for H.265 codec
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("f")][string] $Format="av_mp4", # Format to encode to, in this case MP4
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("q")][string] $Quality="27", # Set the Quality Level for the encoding.  Lower #'s = Better quality with less compression.  For 1080p Use 18-27, For 4K use 28
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("ae")][string] $AEncoder="copy", # Set the Audio Encoder to 'copy' i.e. passthru audio tracks untouched
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("at")][string] $ATracks="1,2,3,4,5,6,7,8,9,10,11,12", # Selects the first 12 available audio tracks, adjust as wanted
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("ac")][string] $ACmask="aac,ac3,eac3,truehd,dts,dtshd,mp2,mp3,flac,opus", # Specifies the types of Audio we will copy/passthru, Otherwise default failback is AAC 2 Channel
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("afb")][string] $AFailBack="av_aac", # Specify what audio codec to use, if we cant passthru the native audio
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("sub")][string] $Subtitles="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20", # Selects the first 20 subtitles to be included
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("rs")][switch] $RemoveSource, # When used, this will delete the source file after a successful encode and validation on target file has occurred
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("rt")][switch] $RemoveTarget=$true, # When true, this will remove the target file if anything goes wrong.
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("dj")][switch] $DebugJobs=$true, # By default the script will remove all jobs once complete, change to =$false to manually debug or pull info from the jobs
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("rjl")][switch] $RemoveJobLogs=$true, # When $true, this will also delete the individual job and validation log files aftee being used
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("jf")][string] $JobFolder = $PSScriptRoot+"\", # Folder MUST exist, defaults to where ever the script is ran from
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("min")][int] $MinCompression="10", # 
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("max")][int] $MaxCompression="70", #
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("minb")][int] $MinBitrate="700", # 
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("maxb")][int] $MaxBitrate="99999", #
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("us")][switch] $UpdateSonarr, # When $true, this will trigger Sonarr to refresh the TV Series
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("sbu")][string] $sonarrBaseUrl = "http://localhost:8989/api/v3",  # Adjust the URL if necessary
    [Parameter(Mandatory=$false,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)] [alias("sak")][string] $SonarrApiKey = ""  # Replace with your actual API key
)

# Version 0.7

# Reset Global Variables
$c=0
$jobsDetails=@()

# Function to send a POST request to Sonarr API
function Invoke-SonarrCommand {
    param (
        [string]$commandName,  # The command name (e.g., "Backup", "RefreshSeries")
        [hashtable]$body = @{}  # Optional body parameters for certain commands
    )

    # Define the API endpoint for commands
    $endpoint = "$sonarrBaseUrl/command"
    
    # Prepare headers for API request
    $headers = @{
        "X-Api-Key" = $SonarrApiKey
        "Content-Type" = "application/json"
    }

    # Convert body parameters to JSON if provided
    $bodyJson = $null
    if ($body.Count -gt 0) {
        $bodyJson = $body | ConvertTo-Json
    }

    # Prepare the request body including the command name
    $postBody = @{
        "name" = $commandName
    }
    if ($bodyJson) {
        $postBody += $body
    }

    # Send the POST request
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body ($postBody | ConvertTo-Json)
        Write-Host "Command '$commandName' executed successfully. Response:" -ForegroundColor Green
        $response
    } catch {
        Write-Host "Error executing command '$commandName': $_" -ForegroundColor Red
    }
}

# Test $JobFolder
if (Test-Path -Path $JobFolder){
    Write-Verbose "Job Folder is valid: $JobFolder"
}
else {
    Write-Host -ForegroundColor Red "The -JobFolder specified: $JobFolder - Doesnt Exist..."
    Exit 1
}

# Get all video files in the source folder
Write-Host -ForegroundColor Blue "Gathering Source file(s) from $Source"
$sourcefiles = Get-ChildItem -Recurse -Path $Source -Filter $SourceExtensions | Sort-Object
Write-Host -ForegroundColor Blue "Detected $($sourcefiles.count) Source Files "

# Exclude from job queue anything specified in $SourceIgnore
Write-Host -ForegroundColor Blue "Removing 'Ignored' Files from Queue"
$files = $sourcefiles | Where-Object {
    $ignore = $false
    foreach ($ignoreString in $SourceIgnore) {
        if ($_.Name -like "*$ignoreString*") {
            $ignore = $true
            break
        }
    }
    -not $ignore
}

# Counters
$filecount=$files.count
Write-Host -ForegroundColor Blue "Detected $filecount videos to be transcoded..."

# Loop through each video file
foreach ($file in $files) {

    # Initialize counters and arrays
    $c++ 
    $SourceaudioTrackCount = 0
    $SourcesubtitleTrackCount = 0
    $SourceaudioTracks = @()
    $SourcesubtitleTracks = @()
    $SourceDuration = @()
    $SourceVideoValid=0
    $SourceSizeValue = ""
    
    $EncodeJob=$null
    $ValidateSourceJob=$null
    $SourceVideoStream=$null
    $SourceVideoDuration=$null
    $ValidateTargetJob=$null
    $TargetVideoStream=$null
    $TargetVideoDuration=$null

    # Get the current date and time in a specific format
    $dateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    
    # Create Job Log Variables 
    Write-Verbose "Job Log File Locations for this run:"
    $JobLogFile = $JobFolder + $dateTime + "_job_" + "$c" + ".log"
    Write-Verbose $JobLogFile
    $SourceLogValidationFile = $JobFolder + $dateTime + "_job_" + "$c" + "_source.log"
    Write-Verbose $SourceLogValidationFile
    $TargetLogValidationFile = $JobFolder + $dateTime + "_job_" + "$c" + "_target.log"
    Write-Verbose $TargetLogValidationFile
        
    # 1st Run
    if ($averageExecutionTime -eq $null){
        # Progress Bar and Status
        Write-Verbose "1st Run"
        Write-Progress -Id 0 -Activity 'Performing Video Transcoding' -Status "Processing Video File $($c) of $filecount" -CurrentOperation "$($file.Name)" -PercentComplete (($c/$filecount) * 100)
    }
    
    # Update progress bar with estimated time remaining
    else {
        Write-Verbose "Job #: $c"
        $estimatedRemainingTime = $averageExecutionTime * ($filecount - $c)
        Write-Progress -Id 0 -Activity 'Performing Video Transcoding' -Status "Processing Video File $($c) of $filecount" -CurrentOperation "$($file.Name)" -PercentComplete (($c/$filecount) * 100) -SecondsRemaining $estimatedRemainingTime
    }

    # Validate the Source file as a background job by scanning it with handbrake
    Write-Host -ForegroundColor Blue "Analyzing the Source file $($file.Name)"
    Write-Progress -Id 1 -ParentId 0 -Activity 'Validation Process' -Status "Using HandBrakeCLI to validate the Source video file" -CurrentOperation $file.Name
    try {
        $ValidateSourceJob = Start-Job -ScriptBlock {& $using:HandBrakeCLI `
            --input $using:file.FullName `
            --scan `
            2> $using:SourceLogValidationFile
        }
    }
    
    # Fail if anything goes wrong with the job
    catch {
        Write-Host -ForegroundColor Red "An Error has occured while trying to validate the Source file:"
        Write-Host $_
        #Get-Job | Remove-Job -Force
        Exit 1
    }

    # Wait for ValidateSourceJob to finish
    while ($ValidateSourceJob.State -eq 'Running'){
        Write-Verbose "Waiting on Source Video Validation job to finish..."
        Start-Sleep 1
    }
    
    # Parse the Source Log Validation File
    Get-Content $SourceLogValidationFile -Raw | ForEach-Object {

        # See if this file is already HEVC, and skip it if so
        if ($_ -match 'hevc' -or $_ -match 'vp9' -or $_ -match 'x265' -or $_ -match 'h265'){
            Write-Host -ForegroundColor Yellow "Skipping: $($file.Name)"    
            Write-Host -ForegroundColor Yellow "Because it is already HEVC/x265/VP9"
            Write-Progress -Id 1 -ParentId 0 -Activity 'Validation Process' -Completed
            Continue # Exit the loop on this source file
        }

        # Check the bitrate of this file to make sure its within our min/max values
        if ($_ -match "bitrate:\s*(\d+)\s*kb/s") {
            # Store the captured value
            [int]$SourceVideoBitrate = $matches[1]
        }

        # Skip this file if it's not within our desired bitrate for encoding
        if ($SourceVideoBitrate -le $MinBitrate){
            Write-Host -ForegroundColor Yellow "Skipping: $($file.Name)"    
            Write-Host -ForegroundColor Yellow "Because it's Bitrate of: $SourceVideoBitrate is below the requested minimum value of $MinBitrate"
            Write-Progress -Id 1 -ParentId 0 -Activity 'Validation Process' -Completed
            Continue # Exit the loop on this source file
        }


        # Match the line containing "libhb: scan thread" and capture the number of valid titles
        if ($_ -match 'libhb:\s*scan thread found\s*(\d+)\s+valid title\(s\)') {
            # Store the captured value
            $SourceVideoValid = $matches[1]
        }

        # Match lines with "size" and capture the size value
        if ($_ -match '^\s*\+\s*size:\s*([\d+x\d+]+)') {
            # Store the captured size value
            $SourceSizeValue = $matches[1]
        }

        # Match lines with "duration" and capture the time value
        if ($_ -match '^\s*\+\s*duration:\s*(\d{2}:\d{2}:\d{2})') {
            # Add the captured duration to the array
            $SourceDuration += $matches[1]
        }
        if ($_ -match '^\s*\+\s*audio tracks:') {
            # Start counting audio tracks
            $inAudioTracks = $true
        }
        elseif ($_ -match '^\s*\+\s*subtitle tracks:') {
            # Stop counting audio tracks
            $inAudioTracks = $false
            # Start counting subtitle tracks
            $inSubtitleTracks = $true
        }
        elseif ($inAudioTracks -and $_ -match '^\s*\+\s*(\d+,\s*.*)') {
            # Store the audio track
            $SourceAudioTracks += $matches[1]
        }
        elseif ($inSubtitleTracks -and $_ -match '^\s*\+\s*(\d+,\s*.*)') {
            # Store the subtitle track
            $SourceSubtitleTracks += $matches[1]
        }
        elseif ($inSubtitleTracks -and $_ -match '^\s*$') {
            # Stop counting subtitle tracks when an empty line is encountered
            $inSubtitleTracks = $false
        }
    }

    Write-Verbose "Source Video Already x265: No"

    # Get the original source file size
    $SourceFileSizeBytes = (Get-Item -LiteralPath $file.FullName).Length
    $SourceFileSize = $SourceFileSizeBytes -as [string] -replace '(\d)(?=(\d{3})+$)', '$1,'

    
    # Output results
    if ($SourceVideoValid -ige 1){Write-Verbose "Source Video Valid: Yes"}
    else {Write-Verbose "Source Video Valid: No"}
    Write-Verbose "Source Video Bitrate: $($SourceVideoBitrate)"
    Write-Verbose "Source Video Resolution: $($SourceSizeValue)"
    Write-Verbose "Source Durations: $($SourceDuration)"
    Write-Verbose "Source Audio Track Count: $($SourceaudioTracks.Count)"
    Write-Verbose "Source Audio Tracks: $($SourceaudioTracks -join ', ')"
    Write-Verbose "Source Subtitle Track Count: $($SourcesubtitleTracks.Count)"
    Write-Verbose "Source Subtitle Tracks: $($SourcesubtitleTracks -join ', ')"
    Write-Verbose "Source Video Size on Disk: $($SourceFileSize)"

    # Validate Video Stream is good, exit the script if not.
    if ($SourceVideoValid  -ige 1){
        Write-Host -ForegroundColor Green "Source Video Stream is Good! $SourceVideoDuration"
        $SourceVideoStreamIsValid = $true
    }
    else {
        Write-Host -ForegroundColor Red "An Error has occured while trying to validate the Source file:"
        Get-Job | Remove-Job -Force
        Exit 1
    }
    
    # Close out the Source Validation progress bar
    Write-Progress -Id 1 -ParentId 0 -Activity 'Validation Process' -Completed
  
    Write-Host -ForegroundColor Blue "Working on $($file.FullName)"
        
    # Determine if we specified a destination manually, or use the same folder as the source by default for each output file
    if ($DestinationFile -eq "" -and $DestinationFolder -eq ""){
        # Construct the output file name
        $sourceFolderPath = $file.Directory.FullName + "\"
        $outputFileName = Join-Path -Path $sourceFolderPath -ChildPath ($file.BaseName + ".mp4") 
    }
    
    elseif ($DestinationFile -ne "") {
        # Destination File was provided, using that for output file instead
        $outputFileName = $DestinationFile
    }
    
    elseif ($DestinationFolder -ne ""){
        # Destination Folder was provided, redirecting all outputs to that folder
        $outputFileName = Join-Path -Path $DestinationFolder -ChildPath ($file.BaseName + ".mp4") 
    }

    # Run HandBrakeCLI with specified options as a background job
    try {
        $EncodeJob = Start-Job -ScriptBlock {& $using:HandBrakeCLI `
            --input $using:file.FullName `
            --output $using:outputFileName `
            --preset $using:Preset `
            --format $using:Format `
            --encoder $using:Encoder `
            --quality $using:quality `
            --aencoder $using:AEncoder `
            --audio $using:ATracks `
            --audio-copy-mask=$using:ACmask `
            --audio-fallback $using:AFailBack `
            --subtitle $using:subtitles `
            > $using:JobLogFile
        }
    }
    
    # Fail if anything goes wrong with the job
    catch {
        Write-Host -ForegroundColor Red "An Error has occured while trying to execute the handbrake job:"
        Write-Host $_
        Get-Job | Remove-Job -Force
        Exit 1
    }

    # Monitor Job Status to main console
    while ($EncodeJob.State -eq 'Running'){
        Start-Sleep 5
        Get-Content $JobLogFile -Tail 1
    }
    
    # Get the previous job details
    $jobDetail = Get-Job -State Completed | Sort-Object -Property EndTime -Descending | Select-Object -First 1
    
    # Calculate the job execution time
    $executionTime = New-TimeSpan -Start $jobDetail.PSBeginTime -End $jobDetail.PSEndTime
    $averageExecutionTime = $executionTime.TotalSeconds

    # Done with last encode job
    Write-Host -ForegroundColor Green "Converted $($file.Name)"
    Write-Host -ForegroundColor Green "  to $($outputFileName)"
    Write-Host -ForegroundColor Green "  in $executionTime"
    Write-Host -ForegroundColor Green " 6 Average encode time is: $averageExecutionTime seconds"

    # Progress Bar
    Write-Progress -Id 2 -ParentId 0 -Activity 'Validation Process' -Status "Using HandBrakeCLI to validate the target video file" -CurrentOperation $outputFileName
    
    # Validate the target file as a background job by scanning it with handbrake
    Write-Host -ForegroundColor Blue "Analyzing the target file outputFileName"
    try {
        $ValidateTargetJob = Start-Job -ScriptBlock {& $using:HandBrakeCLI `
            --input $using:outputFileName `
            --scan `
            2> $using:TargetLogValidationFile
        }
    }
    
    # Fail if anything goes wrong with the job
    catch {
        Write-Host -ForegroundColor Red "An Error has occured while trying to validate the target file:"
        Write-Host $_
        Get-Job | Remove-Job -Force
        Exit 1
    }

    # Wait for ValidateTargetJob to finish
    while ($ValidateTargetJob.State -eq 'Running'){
        Write-Verbose "Waiting on Target Video Validation job to finish..."
        Start-Sleep 1
    }
    
    # Initialize counters
    $TargetaudioTrackCount = 0
    $TargetsubtitleTrackCount = 0

    # Initialize counters and arrays
    $TargetaudioTracks = @()
    $TargetsubtitleTracks = @()
    $TargetDuration = @()
    $TargetVideoValid=0
    $TargetSizeValue = ""
    $CompressionValid= ""

    # Parse the Target Log Validation File
    Get-Content $TargetLogValidationFile | ForEach-Object {

        # Match the line containing "libhb: scan thread" and capture the number of valid titles
        if ($_ -match 'libhb:\s*scan thread found\s*(\d+)\s+valid title\(s\)') {
            # Store the captured value
            $TargetVideoValid = $matches[1]
        }

        # Match lines with "size" and capture the size value
        if ($_ -match '^\s*\+\s*size:\s*([\d+x\d+]+)') {
            # Store the captured size value
            $TargetSizeValue = $matches[1]
        }

        # Match lines with "duration" and capture the time value
        if ($_ -match '^\s*\+\s*duration:\s*(\d{2}:\d{2}:\d{2})') {
            # Add the captured duration to the array
            $TargetDuration += $matches[1]
        }
        if ($_ -match '^\s*\+\s*audio tracks:') {
            # Start counting audio tracks
            $inAudioTracks = $true
        }
        elseif ($_ -match '^\s*\+\s*subtitle tracks:') {
            # Stop counting audio tracks
            $inAudioTracks = $false
            # Start counting subtitle tracks
            $inSubtitleTracks = $true
        }
        elseif ($inAudioTracks -and $_ -match '^\s*\+\s*(\d+,\s*.*)') {
            # Store the audio track
            $TargetAudioTracks += $matches[1]
        }
        elseif ($inSubtitleTracks -and $_ -match '^\s*\+\s*(\d+,\s*.*)') {
            # Store the subtitle track
            $TargetSubtitleTracks += $matches[1]
        }
        elseif ($inSubtitleTracks -and $_ -match '^\s*$') {
            # Stop counting subtitle tracks when an empty line is encountered
            $inSubtitleTracks = $false
        }
    }
    
    # Get the file size of the target file
    $TargetFileSizeBytes = (Get-Item -LiteralPath $outputFileName).Length
    $TargetFileSize = $TargetFileSizeBytes -as [string] -replace '(\d)(?=(\d{3})+$)', '$1,'

    # Output results
    if ($TargetVideoValid -ige 1){Write-Verbose "Target Video Valid: Yes"}
    else {Write-Verbose "Target Video Valid: No"}
    Write-Verbose "Target Video Resolution: $($TargetSizeValue)"
    Write-Verbose "Target Durations: $($TargetDuration)"
    Write-Verbose "Target Audio Track Count: $($TargetaudioTracks.Count)"
    Write-Verbose "Target Audio Tracks: $($TargetaudioTracks -join ', ')"
    Write-Verbose "Target Subtitle Track Count: $($TargetsubtitleTracks.Count)"
    Write-Verbose "Target Subtitle Tracks: $($TargetsubtitleTracks -join ', ')"
    Write-Verbose "Target Video Size on Disk: $($TargetFileSize)"

    # Validate Target Video Stream is Good
    if ($TargetVideoValid -ige 1){
        Write-Host -ForegroundColor Green "Target Video Stream is Good! $TargetVideoDuration"
        $TargetStreamIsValid = $true
    }
    else {
        Write-Host -ForegroundColor Red "An Error has occured while trying to validate the Target file:"
        if ($RemoveTarget -eq $true){Remove-Item -LiteralPath $outputFileName -Force -Confirm:$false} # Performs the deletion on target video file upon failed validation}
        Get-Job | Remove-Job -Force
        Exit 1
    }

    # Validate if duration matches source
    if ($SourceDuration -eq $TargetDuration){
        $VideoDurationIsValid = $true
        Write-Host -ForegroundColor Green "Source & Target Video Durations are a match!"
    }

    # Validate all audio tracks matches source
    if ($SourceaudioTracks.Count -eq $TargetaudioTracks.Count){
        $AudioTracksIsValid = $true
        Write-Host -ForegroundColor Green "Source & Target Audio Tracks are a match!"
    }

    # Validate all subtitle tracks matches source
    if ($SourcesubtitleTracks.Count -eq $TargetsubtitleTracks.Count){
        $SubtitleTracksIsValid = $true
        Write-Host -ForegroundColor Green "Source & Target Subtitle Tracks are a match!"
    }

    # Validate compression ratio meets desired outcome
    $CompressionRatio = [math]::Round((($SourceFileSizeBytes - $TargetFileSizeBytes) / $SourceFileSizeBytes) * 100)
    if ($CompressionRatio -ge $MinCompression -and $CompressionRatio -le $MaxCompression){
        $CompressionValid = $true
    }
    elseif ($CompressionRatio -le $MinCompression) {
        $CompressionValid = $false
        Write-Host -ForegroundColor Red "Compression Ratio of: $CompressionRatio is below the Minimum requested ratio of $MinCompression"
    }
    elseif ($CompressionRatio -ge $MaxCompression) {
        $CompressionValid = $false
        Write-Host -ForegroundColor Red "Compression Ratio of: $CompressionRatio is above the Maximum requested ratio of $MaxCompression"
    }

    # If all validations are successful, lets call it successful
    if ($SourceVideoStreamIsValid -eq $true -and $VideoDurationIsValid -eq $true -and $AudioTracksIsValid -eq $true -and $SubtitleTracksIsValid -eq $true -and $CompressionValid -eq $true){
        $EncodedVideoIsValid = $True
        Write-Host -ForegroundColor Green "Validation of Target File --> $outputFileName"
        Write-Host -ForegroundColor Green "Was Succesful! Video stream is valid, Durations match, and Audio & Subtitle tracks match!"
        Write-Host -ForegroundColor Green "Target file has been compressed: $CompressionRatio %"
    }

    # Close out the Target Validation progress bar
    Write-Progress -Id 2 -Activity 'Validation Process' -Status "Done" -Completed

    ###
    ### Determine if we are to delete the source file upon successful encode
    ###

    # Encode Job NOT Valid
    if ($RemoveSource -eq $true -and $EncodedVideoIsValid -ne $true){
        # Do NOT remove the original source file
        Write-Host -ForegroundColor Red "Failed to Remove --> $original"
        Write-Host -ForegroundColor Red "Validation of encoded file failed..."
        if ($RemoveTarget -eq $true){Remove-Item -LiteralPath $outputFileName -Force -Confirm:$false} # Performs the deletion on target video file upon failed validation}
    }
    
    # Compression Ratio NOT Valid
    elseif ($RemoveSource -eq $true -and $CompressionValid -ne $true){
        # Do NOT remove the original source file
        Write-Host -ForegroundColor Red "Failed to Remove --> $original"
        Write-Host -ForegroundColor Red "The compression value of $CompressionRatio is above or below the requested values..."
    }
    
    # RemoveSource NOT requested
    elseif ($RemoveSource -eq $false -and $EncodedVideoIsValid -eq $true) {
        # Do NOT remove the original source file
        Write-Host -ForegroundColor Green "Validation of $outputFileName was Sucessfull!"
        Write-Host -ForegroundColor Green "Source File was not requested to be removed, please validate and remove manually..."
        Write-Host -ForegroundColor Green "$TargetVideoStream" # Displays the output for the Video stream validation
        Write-Host -ForegroundColor Green "$TargetVideoDuration" # Displays the output for the video duration
    }
    
    # RemoveSource IS requested, and all checks are valid, will try to remove source file
    elseif ($RemoveSource -eq $true -and $EncodedVideoIsValid -eq $true -and $CompressionValid -eq $true){
        # Remove the original source file
        $original = $sourceFolderPath + $file.Name
        try {
            Write-Host -ForegroundColor Blue "Removing --> $original"
            Remove-Item -LiteralPath $original -Force -Confirm:$false # Performs the deletion on source video file upon successful validation
            Start-Sleep 2 # Allows for some time to pass before checking if the file still remains
        }
        catch {
            Write-Host -ForegroundColor Red "Failed to Remove --> $original"
            Write-Host -ForegroundColor Red "Most likely a permissions issue..."    
            Write-Host -ForegroundColor Red "Manually delete the original source file(s)"
            Exit 1    
        }
        if (Test-Path $original){ # Validate that the source file was deleted
            Write-Host -ForegroundColor Green "Validation of File was deletion was succesful."
            Write-Host -ForegroundColor Green "Removed --> $original"

        }
    }

    # Clean up this Job's logfiles
    if ($RemoveJobLogs -eq $true){
        Write-Verbose "Done with this Job's logfiles.  Removing them from disk."
        Remove-Item $JobLogFile -Force -Confirm:$false
        Remove-Item $SourceLogValidationFile -Force -Confirm:$false
        Remove-Item $TargetLogValidationFile -Force -Confirm:$false
    }

    # Clean all jobs from this run
    if ($DebugJobs -eq $true){
        Write-Verbose "Background jobs complete for this run.  Removing them from background tasks."
        Get-Job | Remove-Job -Force
    }

    # Update Sonarr with the new target file if job was successful
    if ($UpdateSonarr -eq $true -and $EncodedVideoIsValid -eq $True){
        # Create a web request to get the series list
        try {
            $response = Invoke-RestMethod -Uri "$sonarrBaseUrl/series" -Method Get -Headers @{ "X-Api-Key" = $SonarrApiKey }

            # Output the series list
            $Series = $response | ForEach-Object {
                [PSCustomObject]@{
                    Title       = $_.title
                    Id          = $_.id
                    Status      = $_.status
                    Path        = $_.path  # This is the full path of the series
                }
            } 
            $Series = $Series | Sort-Object -Property Path
        } catch {
            Write-Host "Error connecting to Sonarr API: $_"
        }

        # Find the series that matches the folder path
        $SourceSeries = $source -replace '\\Season \d{2}.*', ''
        $seriesId = ($series | Where-Object { $_.path -like $($SourceSeries) }).id
        $seriesTitle = ($series | Where-Object { $_.path -like $($SourceSeries) }).title
        Write-Verbose "Sonarr:  Found matching Series: $SourceSeries with SeriesID: $seriesID"
        
        $currentSeries = Invoke-RestMethod -Uri "$sonarrBaseUrl/series/$seriesId" -Headers @{ "X-Api-Key" = $SonarrApiKey }
        
        # Send the request to refresh the series
        try {
            Invoke-SonarrCommand -commandName "RescanSeries" -body @{ seriesId = $seriesId }
            # Output the response
            Write-Host -ForegroundColor Blue "Sonarr : Refresh command sent for Series $seriesTitle : ID $seriesId."
            Start-Sleep 3
        } catch {
            Write-Host "Error connecting to Sonarr API: $_"
        }

        # Send the request to rename files in this series
        try {
            Invoke-SonarrCommand -commandName "RenameSeries" -body @{ seriesId = $seriesId }
            # Output the response
            Write-Host -ForegroundColor Blue "Sonarr : Rename command sent for Series $seriesTitle : ID $seriesId."
        } 
        catch {
            Write-Host "Error connecting to Sonarr API: $_"
        }

    } #/update Sonarr

} #/foreach

# Clean any leftover jobs from this run
if ($DebugJobs -eq $true){
    Write-Verbose "Removing any leftover jobs."
    Get-Job | Remove-Job -Force
}

# Close out the progress bar
Write-Progress -Id 0 -Activity 'Performing Video Transcoding' -Status "Done" -Completed

# Done