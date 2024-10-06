# handlebrake

A PowerShell script to 'handle' the automation and validation of HandBrakeCLI batch encoding jobs

## Description

I've been searching for, and found a lot of other people also looking for, and struggling with using HandBrakeCLI to convert 1080p H264 content in to H265.
Not only on the video conversion, but with audio passthrough _(i.e. don't re-encode audio tracks)_
And include any subtitle tracks if applicable.
This script handles that, and much more :)


**My goals are to:**

* Be able to point it at any individual file, or root folder containing multiple video files, but also be able to filter out for: Any desired values in the file name, or file extensions.
* Take high bitrate low compression H264 videos, and compress them with minimal video loss, using the HandBrakeCLi preset = H.265 NVENC 1080p.  (Leveraging Nvidia GPU for the encoding)
* Passthrough all Audio tracks as-is where possible & bring over all the Subtitle tracks as well.
* Progress monitoring, logging, and validation on all Jobs.
* Scan the Source video files for each job, and gather the metadata.
* Skip the Source video file, if it's already hevc, x265, h265, vp9 in it's metadata
* Transcode the file(s)
* Monitor compression in Real-Time, and abort encode job after 20% if the results are undesirable  (Min/Max Compression values)
* Scan the target video files for each job, and gather the metadata.
* Compare the Source & Target metadata for validation on Video Stream, Duration, Audio & Subtitle track counts.
* Remove the source file (if all validations are a success, when the -RemoveSource flag is provided)
* Measure the average encoding job duration, compression %, space saved in GB, and use that to update the Progress Bar with the ETA and metrics for the entire Queue
* Integration with Sonarr, if the file is part of a monitored TV Series, force a rescan & rename after successful encode.  (If you have renaming enabled in Sonarr)'

**Future Features:**

* Integration with Radarr
* Integration with Plex
* Add CPU encoding, and a switch to set preference between GPU & CPU
* Failback to CPU encoding if GPU encoding can't achieve desired minimum compression


**Note:**  Because HandBrakeCLI is 'noisy' and emits progress to stdout and log info to stderr.  All jobs run in a background, and are logged and monitored for success.  This allowed the main script session to be much cleaner and provide working progress bars.

## Getting Started
Please read the Default Configuration and understand the assumptions before you accept the values for your use case

### Dependencies

* Requires PowerShell _(Tested on Windows with PowerShell v5.1 and 7.4.5)_
* Requires PowerShell to be able to run 'unsigned' scripts such as this one.  _(Set-ExecutionPolicy Unrestricted -Force)_
* Requires HandBrakeCLI _(Tested on v1.8.2 - latest at the time of creation)_
* https://handbrake.fr/rotation.php?file=HandBrakeCLI-1.8.2-win-x86_64.zip

### Installing

* Download the latest --> handlebrake.ps1 <-- from this repo, and copy it to wherever you want to launch it from

   _Example:  C:\Scripts\handlebrake.ps1_
* If your HandBrakeCLI isn't installed in the default windows path of: _(C:\Program Files\HandbrakeCLI\HandBrakeCLI.exe)_

  Then you need to modify the following line in the Parameters section on the very top
```
$HandBrakeCLI="C:\Program Files\HandbrakeCLI\HandBrakeCLI.exe"
to
$HandBrakeCLI="X:\Where Ever The\Actual Path Is\HandBrakeCLI.exe"
```

### Executing handlebrake.ps1

* Launch PowerShell and navigate to your script folder
```
CD C:\Scripts
```
* Basic Usage
```
.\handlebrake.ps1 -Source <Source Path>
```
Where "Source Path" is either a single file, or a folder containing files you wish to encode

* Examples
```
.\handlebrake.ps1 -Source "Z:\Videos\Home Movies\2023\"
.\handlebrake.ps1 -Source "Z:\Videos\Home Movies\2023\01_01_2023.mkv"
.\handlebrake.ps1 -Source "Z:\Videos\TV\TV Show\"
.\handlebrake.ps1 -Source "Z:\Videos\TV\TV Show\Season 01\"
```

## 

**Optional Features**

Verbose Mode - Adds additional console output around Source & Target meta-data, validations, debug & logging, etc
```
.\handlebrake.ps1 -Source <Source Path> -Verbose
```
Remove Source Files - After each successful encode _(Only if the validation is 100% success)_
```
.\handlebrake.ps1 -Source <Source Path> -RemoveSource
```
**Validation Process for -RemoveSource**
* Before each Job the script will do a --SCAN run on the source and collect the media metadata
* After the encode job, the script will do another --SCAN against the target file and collect the media metadata
* Then it will compare the two files and make sure: The video stream is valid, the duration matches, the # of audio tracks match, and the # of subtitle tracks match
* Finally it will check that the compression ratio was acceptable. (Between the Min and Max compression values)
* All of those must be true, in addition to sending the -RemoveSource parameter when executing the script for it to automatically remove the source video file(s)

Include Only - An optional way to search for files across a large folder structure, and filter based on file names for source jobs to encode
```
.\handlebrake.ps1 -Source <Source Path> -IncludeOnly -IncludeOnlyString=@('SomeFiles','IwantTo','Encode')
```
Only files in the -Source , which have any of the values provided in their file name will be considered for the queue.

## Default Usage and Advanced Options

### Default Configuration
* The default configuration assumes you want to convert 1080p H264 .MKVs to --> 1080p H265 .MP4s using Nvidia GPU
* And the file names will be identical except for maybe the extension, and the output files will be in the same folders as the sources
* It also assumes you don't want to re-encode any audio tracks, and just copy them over as-is
* It also assumes if there are any subtitle tracks, you want those and brings them over as well (within the limits of handbrake itself)
* All of the defaults can be configured in the script itself at the very top under:
```
[CmdletBinding()]Param(
```
* Or alternatively you can provide your own values as needed when running the script by providing a "value" to any of the -parameters
* Which will ignore the defaults, and use whatever you gave it

**Input / Output Parameters** 
* By default the **-SourceExtensions** is set to **"*.mkv","*.mp4"** which will only add video files that have that the .mkv file extension
* By default the **-ExcludeExtensions** is set to **blank** which can be used to exclude any file extensions you may need
* By default the **-SourceIgnore** is set to **'MeGusta','x265','h265','Vault42'** which ignore any files which have any of those strings in its name from being processed, saves detection & skipping later
* By default the **-DestinationFolder** is **blank**, which will default the encoded output file to be in the same folder as the source
* By default the **-DestinationFile** is **blank**, which is only ever used when you have a single -Source file, and you want to redirect both the output folder and specify the output file name
* By default the **-RemoveSource** is **blank**, which tells the script NOT to remove the source file(s) after successful encoding
* By default the **-RemoveTarget** is **$true**, which tells the script to remove the target file(s) after failing any validations
* By default the **-TranscodeFolder** is **blank**, which tells the script to use a specific folder while transcoding
* Note: Works best on network share, because the real time capacity of the file is accurate.  Plus its a relatively low KB/s bandwidth requirement, so why wear out your precious NVMes :)
* Note: If you try a local disk and the file size stays at 0KB because of File System caching, it will interfer with the Real-Time compression detection
* By default the **-TranscodeFolderDelay** is **2**, works with -TranscodeFolder, and is the delay in seconds to wait after encoding for the file to finish writing, before any action is taken against it
* By default the **-MoveOnSuccess** is **$true**, works with -TranscodeFolder and -RemoveSource, to allow for same name conflicts
* By default the **-IncludeOnly** is **$false**, works with -IncludeOnlyString, add -IncludeOnly to make it true, when you want to filter source files based file name matches
* By default the **-IncludeOnlyString** is **blank**, works with -IncludeOnly flag.  This accepts one or more 'strings' to filter -Source for to limit the scope of the search

**Video Encoding Parameters**
* By Default the **-Preset** is set to **"H.265 NVENC 1080p"**, which specifies the HandBrakeCLI default preset I use by default
* By Default the **-Encoder** is set to **"nvenc_h265"**, which specifies the HandBrakeCLI encoder to use Nvidia GPU
* By Default the **-Format** is set to **"av_mp4"**, which specifies the output encoded file format/extension
* By Default the **-Quality** is set to **"27"**, which specifies a quality level of 27
* By Default the **-MinCompression** is set to **10**, which specifies the minimum compression level acceptable for any encode job
* By Default the **-MaxCompression** is set to **70**, which specifies the maximum compression level acceptable for any encode job
* By Default the **-MonitorCompression** is set to **20**, which specifies what % of the encode job must complete before real-time detection aborts the job, if -MinCompression isn't being met
* By Default the **-MinBitrate** is set to **600**, which specifies the minimum bitrate level to attempt to transcode
* By Default the **-MaxBitrate** is set to **99999**, which specifies the maximum bitrate level to attempt to transcode

**Audio Encoding Parameters**
* By Default the **-AEncoder** is set to **"copy"**, which specifies to attempt to bring over the audio tracks as-is
* By Default the **-ATracks** is set to **"1,2,3,4,5,6,7,8,9,10,11,12"**, which specifies which audio tracks to bring over
* By Default the **-ACmask** is set to **"aac,ac3,eac3,truehd,dts,dtshd,mp2,mp3,flac,opus"**, which specifies types audio tracks to bring over as-is
* By Default the **-AFailBack** is set to **"av_aac"**, which specifies the audio codec to fail back to, if the copy passthrough doesnt work for any reason

**Subtitle Encoding Parameters**
* By Default the **-Subtitles** is set to **"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20"**, which specifies which subtitle tracks to bring over

**Debug & Job Log Parameters**
* By Default the **-JobFolder** is set to **$PSScriptRoot**, which specifies where to create the job logs, by default it's the same folder the script was executed from
* By Default the **-DebugJobs** is set to **"$true"**, which specifies to automatically remove the Powershell background jobs as they complete successfully
* By Default the **-RemoveJobLogs** is set to **"$true"**, which specifies to automatically remove the text based .log files as they complete successfully
* If you want to see the contents of the Jobs or Job Logs yourself, you can run the script with the following settings to tell it not to remove them automatically
```
.\handlebrake.ps1 -Source <Source Path> -DebugJobs=$false -RemoveJobLogs=$false
```
* The Log files will be in the same folder you ran the script from (assuming you didnt redirect the log output folder)
* The Log files are time stamped (from the start of the job itself) for each Job_#
* There are (3) log files for each job, the source scan, the encode job itself, and the target scan
* To get the background PowerShell Job's themselves for manual investigation
```
Get-Jobs | Format-Table -Auto -Wrap
Get-Job[0] | Format-List
```
* To manually remove the leftover jobs, either close out the PowerShell window -or-
```
Get-Jobs | Remove-Jobs -Force
```

**Sonarr Integration Parameters**
* By Default the **$UpdateSonarr** is **Blank**, update to $true to enable Sonarr Integration
* By Default the **$sonarrBaseUrl** is **"http://localhost:8989/api/v3"**, update to your host address:port as required
* By Default the **$SonarrApiKey** is **Blank**, update to your Sonarr API Key
* Note: This will detect and rename the [h264] to [h265] if you have the codec as part of your Sonarr file naming template (i.e. MediaInfo VideoCodec)
* Note: Which if you have Sonarr already connected to a Plex or Jellyfin server, will also trigger the refresh there.
```
.\handlebrake.ps1 -Source "Source Path" -Verbose -UpdateSonarr -SonarrApiKey "api key"
```

**Recommended Parameters**
* -Verbose           Adds significant output to the console with all metadata and validation outputs
* -RemoveSource      Remove the source file, after 100% validated successful encode
* -TranscodeFolder   Encoded file is created in a temp location, and moved to the source folder after the original is removed (allows for same name encode jobs)
```
.\handlebrake.ps1 -Source "Source Path" -Verbose -RemoveSource -TranscodeFolder "Z:\transcode\"
```

## Authors

damburgey (aka StorageGuru)

## Version History

* 0.9d
	* Added -IncludeOnly, defaults to false, add -IncludeOnly to enable
	* Added -IncludeOnlyString (one or more values to filter file names by, to limit the scope of the queue to only requested values)
	* Fixed 'average compression' metric, by reducing the Job Queue # by 1, each time a file is skipped.

* 0.9b
	* Added job queue average compression & space savings (GB) to progress bar
	* Added -ExcludeExtensions for additional source file filtering options

* 0.9a
	* Added -TranscodeFolderDelay with a default of 2 seconds, to wait after encode, before attempting to touch the file
	* Cleaned up Encode Job console output & combined - Real-Time Compression Ratio: % to the background job's direct handbrakecli output
	* Cleaned up / added commenting throughout script

* 0.9
	* Added 'Real-Time' compression Monitor w/ abort job & continue workflow
	* Based on -MinCompression value
	* Added -MonitorCompression, what % of the encode job (defaults to 20%), to make the determination on if compression is going to be acceptable or not
	* If at -MonitorCompression % of encode job, the -MinCompression isn't being met, abort the encode job, clean-up, and move on to the next file
	
* 0.8d
	* Minor code fixes
	* Allowed for Source video duration and Target video duration to match if within +/- 1 second
	* Changed $SourceExtensions to allow for multiple extensions
	* This along with -TranscodeFolder below, can encode, validate, and overwrite files with the same name
	* Without -TranscodeFolder, it would be possible to have naming conflicts when encoding a .mp4 to .mp4 in the same folder/file name.ext

* 0.8
	* Added optional $TranscodeFolder (temp folder for encode job)
	* And $MoveOnSuccess=$true
	* This allows for encoding jobs to replace the source file, when the file names would be identical

* 0.7
	* Added $MinBitrate and $MaxBitrate
	* Will skip passed the source video and not try to encode it, if the detected Bitrate isn't within our desired parameters

* 0.6
	* Added video detection on source file for x265, h265, hevc, vp9
	* Will skip passed the video and continue the queue

* 0.5
	* Added integration with Sonarr
	* Upon successful encode, it will detect the SeriesID and push the Refresh/Scan & Rename via API
	* Note if your Sonarr is connected to Plex/Jellyfin, it should also push the API based on rename action

* 0.4
	* Added Min and Max Compression value parameters
	* If the target encoded file is < than the minimum or > than the maximum desired compression 
	* --> Then the script will reject the target file, and by default remove it as well

* 0.3
    * Added verbose output for source and target video file sizes
	* Added compression ratio calculation in output after each successful encode

* 0.2
    * Initial Release - On this new/final repo
    * $SourceIgnore now accepts an @('array','of','values) - for source file exclusion/filters
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release - On the previous repo posted on reddit

## License

This project is unlicensed, and is available for free to anyone.
