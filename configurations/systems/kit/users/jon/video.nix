{ pkgs, lib, ... }: let 

  inherit (lib) mkShellScript;
  
  # Convert all h264 mp4 files in directory to av1_nvenc pcm audio to edit in Davinci Resolve
  av1ify = mkShellScript { inputs = [ pkgs.ffmpeg ]; name = "av1ify"; text = ./bin/av1ify.sh; };
  
  # Convert output video from Davinci Resolve to x264 mp4 with aac audio
  x264ify = mkShellScript { inputs = [ pkgs.ffmpeg ]; name = "x264ify"; text = ./bin/x264ify.sh; };

in {

  # Packages
  home.packages = with pkgs; [ 
    av1ify
    davinci-resolve
    ffmpeg
    shotcut
    x264ify
  ];

}
