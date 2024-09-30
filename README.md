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
```

## 

**Optional Features**

Verbose Mode - Adds additional console output around Source & Target meta-data, validations, debug & logging, etc
```
.\handlebrake.ps1 -Source <Source Path> -Verbose
```
Remove Source Files - After each successful encode
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

**Video Encoding Parameters**
* By Default the **-Preset** is set to **"H.265 NVENC 1080p"**, which specifies the HandBrakeCLI default preset I use by default
* By Default the **-Encoder** is set to **"nvenc_h265"**, which specifies the HandBrakeCLI encoder to use Nvidia GPU
* By Default the **-Format** is set to **"av_mp4"**, which specifies the output encoded file format/extension
* By Default the **-Quality** is set to **"27"**, which specifies a quality level of 27

**Audio Encoding Parameters**
* By Default the **-AEncodert** is set to **"copy"**, which specifies to attempt to bring over the audio tracks as-is
* By Default the **-ATracks** is set to **"1,2,3,4,5,6,7,8,9,10,11,12"**, which specifies which audio tracks to bring over
* By Default the **-ACmask** is set to **"aac,ac3,eac3,truehd,dts,dtshd,mp2,mp3,flac,opus"**, which specifies types audio tracks to bring over as-is
* By Default the **-AFailBack** is set to **"av_aac"**, which specifies the audio codec to fail back to, if the copy passthrough doesnt work for any reason

**Subtitle Encoding Parameters**
* By Default the **-Subtitles** is set to **"1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20"**, which specifies which subtitle tracks to bring over

**Debug & Job Log Parameters**
* By Default the **-DebugJobs** is set to **"$true"**, which specifies to automatically remove the Powershell background jobs as they complete successfully
* By Default the **-RemoveJobLogs** is set to **"$true"**, which specifies to automatically remove the text based .log files as they complete successfully
* If you want to see the contents of the Jobs or Job Logs yourself, you can run the script with the following settings to tell it not to remove them automatically
```
.\handlebrake.ps1 -Source <Source Path> -DebugJobs=$false -RemoveJobLogs=$false
```
* The Log files will be in the same folder you ran the script from (assuming you didnt redirect the log output folder)
* The Log files are time stamped (from the start of the job itself) for each Job_#
* There are (3) log files for each job, the source scan, the encode job itself, and the target scan
* To get the Job's themselves for manual investigation
```
Get-Jobs | Format-Table -Auto -Wrap
Get-Job[0] | Format-List
```
* To manually remove the leftover jobs, either close out the PowerShell window -or-
```
Get-Jobs | Remove-Jobs -Force
```

## Authors

damburgey (aka StorageGuru)

## Version History

* 0.2
    * Initial Release - On this new/final repo
    * $SourceIgnore now accepts an @('array','of','values) - for source file exclusion/filters
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release - On the previous repo posted on reddit

## License

This project is unlicensed, and is available for free to anyone.
