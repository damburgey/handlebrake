# handlebrake

A PowerShell script to 'handle' the automation and validation of HandBrakeCLI batch encoding jobs

## Description

I've been searching for, and found a lot of other people also looking for, and struggling with using HandBrakeCLI to convert 1080p H264 content in to H265.
Not only on the video conversion, but with audio passthrough _(i.e. don't re-encode audio tracks)_
And include any subtitle tracks if applicable.

**My goals were to:**

* Be able to point it at any individual file, or root folder containing multiple video files, but also be able to filter out for specific file extensions, and ignore certain files with specific things in their name.
* Take high bitrate low compression H264 videos, and compress them with minimal video loss, using the HandBrakeCLi preset = H.265 NVENC 1080p.
* Passthrough all Audio tracks as-is where possible & bring over all the Subtitle tracks as well.
* Progress monitoring, logging, and validation on all Jobs
* Scan the Source video files for each job, and gather the metadata
* Transcode the file(s)
* Scan the target video files for each job, and gather the metadata
* Compare the Source & Target metadata for validation on Video Stream, Duration, Auto & Subtitle track counts.
* Remove the source file (if all validations are a success, and I provide the -RemoveSource flag)
* After the first, and each susbequent job, measure the average encode duration, and use that along with the # of remaining jobs in queue to estimate time remaining for all jobs
* Integration with Sonarr, if the file is part of a monitored TV Series, force a rescan after successful encode

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
* All of those must be true, in addition to sending the -RemoveSource parameter when executing the script for it to automatically remove the source video file(s)


## Default Usage and Advanced Options

### Default Configuration
* The default configuration assumes you want to convert 1080p H264 .MKVs to --> 1080p H265 .MP4s using Nvidia GPU
* And the file names will be identical except for the extension, and the output files will be in the same folders as the sources
* It also assumes you don't want to re-encode any audio tracks, and just copy them over as-is
* It also assumes if there are any subtitle tracks, you want those and brings them over as well (within the limits of handbrake itself)
* All of the defaults can be configured in the script itself at the very top under:
```
[CmdletBinding()]Param(
```
* Or alternatively you can provide your own values as needed when running the script by providing a "value" to any of the -parameters
* Which will ignore the defaults, and use whatever you gave it

**Input / Output** 
* By default the **-SourceExtension** is set to **"*.mkv"** which will only add video files that have that the .mkv file extension
* By default the **-SourceIgnore** is set to **'MeGusta','x265','Vault42'** which ignore any files which have any of those strings in its name from being processed
* By default the **-DestinationFolder** is **blank**, which will default the encoded output file to be in the same folder as the source
* By default the **-DestinationFile** is **blank**, which is only ever used when you have a single -Source file, and you want to redirect both the output folder and specify the output file name
* By default the **-RemoveSource** is **blank**, which tells the script NOT to remove the source file(s) after successful encoding
* By default the **-RemoveTarget** is **$true**, which tells the script to remove the target file(s) after failing any validations

**Video Encoding Parameters**
* By Default the **-Preset** is set to **"H.265 NVENC 1080p"**, which specifies the HandBrakeCLI default preset I use by default
* By Default the **-Encoder** is set to **"nvenc_h265"**, which specifies the HandBrakeCLI encoder to use Nvidia GPU
* By Default the **-Format** is set to **"av_mp4"**, which specifies the output encoded file format/extension
* By Default the **-Quality** is set to **"27"**, which specifies a quality level of 27
* By Default the **-MinCompression** is set to **10**, which specifies the minimum compression level acceptable for any encode job
* By Default the **-MaxCompression** is set to **70**, which specifies the maximum compression level acceptable for any encode job
* By Default the **-MinBitrate** is set to **600**, which specifies the minimum bitrate level to attempt to transcode
* By Default the **-MaxBitrate** is set to **9999**, which specifies the maximum bitrate level to attempt to transcode

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

**Sonar Integration Parameters**
* By Default the **$UpdateSonarr** is **Blank**, update to $true to enable Sonarr Integration
* By Default the **$sonarrBaseUrl** is **"http://localhost:8989/api/v3"**, update to your host address:port as required
* By Default the **$SonarrApiKey** is **Blank**, update to your Sonarr API Key

## Authors

damburgey (aka StorageGuru)

## Version History

* 0.7
	* Added $MinBitrate and $MaxBitrate
	* Will skip passed the video if the detected Bitrate isn't within our desired parameters

* 0.6
	* Added video detection on source file for x265, h265, hevc, vp9
	* Will skip passed the video and continue the queue

* 0.5
	* Added integration with Sonarr
	* Upon successful encode, it will detect the SeriesID and push the Refresh/Scan & Rename via API

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
