{ pkgs, lib, ... }: let 

  inherit (lib) mkShellScript;
  
  # Convert all h264 mp4 files in directory to av1_nvenc pcm audio to edit in Davinci Resolve
  davinci-resolve-import = mkShellScript { 
    inputs = [ pkgs.ffmpeg ]; 
    name = "davinci-resolve-import"; 
    text = ./bin/davinci-resolve-import.sh; 
  };
  
  # Convert output video from Davinci Resolve to x264 mp4 with aac audio
  davinci-resolve-export = mkShellScript { 
    inputs = [ pkgs.ffmpeg ]; 
    name = "davinci-resolve-export"; 
    text = ./bin/davinci-resolve-export.sh; 
  };

in {

  home.packages = with pkgs; [ 

    # Video exiting software
    davinci-resolve

    # Import/export video conversion scripts
    davinci-resolve-import
    davinci-resolve-export

    # Convert video from format to another
    ffmpeg

    # Alternative vidoe editing software
    shotcut

  ];

}
