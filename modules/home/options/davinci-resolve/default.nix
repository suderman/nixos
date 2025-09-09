{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.davinci-resolve;
  inherit (flake.lib) mkScript;
  inherit (lib) mkIf;

  # Convert all h264 mp4 files in directory to av1_nvenc pcm audio to edit in Davinci Resolve
  davinci-resolve-import = mkScript {
    inputs = [pkgs.ffmpeg];
    name = "davinci-resolve-import";
    text = ./davinci-resolve-import.sh;
  };

  # Convert output video from Davinci Resolve to x264 mp4 with aac audio
  davinci-resolve-export = mkScript {
    inputs = [pkgs.ffmpeg];
    name = "davinci-resolve-export";
    text = ./davinci-resolve-export.sh;
  };
in {
  options.programs.davinci-resolve = {
    enable = lib.options.mkEnableOption "Davinci Resolve";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Video exiting software
      davinci-resolve

      # Import/export video conversion scripts
      davinci-resolve-import
      davinci-resolve-export

      # Convert video from format to another
      ffmpeg

      # Alternative video editing software
      shotcut
    ];
  };
}
