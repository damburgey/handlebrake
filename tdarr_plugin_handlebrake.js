/* eslint-disable */
const details = () => ({
  id: "Tdarr_plugin_Vault42",
  Stage: 'Pre-processing',
  Name: "Vault42",
  Type: "Video",
  Operation: "Transcode",
  Description: "Soon™",
  Version: "0.1a",
  Link: "Soon™"
});

// eslint-disable-next-line no-unused-vars
const plugin = (file, librarySettings, inputs, otherArguments) => {
const importFresh = require('import-fresh');
const library = importFresh('../methods/library.js');

//Must return this object at some point
const response = {
   processFile : false,
   preset : '',
   container : '.mkv',
   handbrakeMode : true,
   ffmpegMode : false,
   reQueueAfter : true,
   infoLog : '',

}

response.infoLog += "" + library.filters.filterByCodec(file,"exclude","hevc,x265").note

if((true &&library.filters.filterByCodec(file,"exclude","hevc,x265,MeGusta,Vault42").outcome === true) || file.forceProcessing === true){
    response.preset = '-Z "H.265 NVENC 1080p" --format "av_mp4" --encoder "nvenc_h265" --format "av_mp4" --quality "27" --aencoder "copy" --audio "1,2,3,4,5,6,7,8,9,10,11,12" --audio-copy-mask "aac,ac3,eac3,truehd,dts,dtshd,mp2,mp3,flac,opus" --audio-fallback "av_aac" --subtitle "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20"'
    response.container = '.mp4'
    response.handbrakeMode = true
    response.ffmpegMode = false
    response.processFile = true
    response.infoLog +=  "File is being transcoded using custom arguments \n"
    return response
   }else{
    response.infoLog += "File is being transcoded using custom arguments \n"
    return response
   }
}

module.exports.details = details;
module.exports.plugin = plugin;