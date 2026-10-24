{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.davinci-resolve;
  inherit (lib) getExe mkIf mkOption types;

  # Remux AAC audio to PCM so Resolve on Linux can play it. Runs inside the
  # package's FHS wrapper, where fusionscript.so finds its libraries.
  davinci-resolve-aac = pkgs.self.mkScript {
    name = "davinci-resolve-aac";
    text = let
      inner = cfg.package.davinci;
    in
      # bash
      ''
        caller=$PWD
        cd "$HOME" # the FHS sandbox may not contain the caller's directory
        exec ${getExe cfg.package} python3 -I ${./davinci-resolve-aac.py} \
          --output-dir ${lib.escapeShellArg cfg.aacRepair.directory} \
          --ffmpeg ${pkgs.ffmpeg}/bin/ffmpeg \
          --ffprobe ${pkgs.ffmpeg}/bin/ffprobe \
          --notify ${pkgs.libnotify}/bin/notify-send \
          --script-api ${inner}/Developer/Scripting \
          --script-lib ${inner}/libs/Fusion/fusionscript.so \
          --cwd "$caller" \
          "$@"
      '';
  };

  # Resolve 21.1+'s own MCP server, at a stable name for agent configuration
  # (the agents repo declares it). Its bundled Python needs the FHS wrapper.
  davinci-resolve-mcp = pkgs.self.mkScript {
    name = "davinci-resolve-mcp";
    text =
      # bash
      ''
        cd "$HOME" # agents start servers in project directories the sandbox may lack
        exec ${getExe cfg.package} ${cfg.package.davinci}/bin/ResolveMCP "$@"
      '';
  };

  # Make Resolve renders web-friendly: H.264/AAC MP4, copying video Resolve
  # already encoded as H.264 or HEVC. Linux Resolve cannot encode AAC.
  davinci-resolve-export = pkgs.self.mkScript {
    name = "davinci-resolve-export";
    path = [pkgs.ffmpeg];
    text =
      # bash
      ''
        if [[ $# -eq 0 ]]; then
          echo "Usage: davinci-resolve-export FILE..." >&2
          exit 1
        fi
        for file in "$@"; do
          output="''${file%.*}-final.mp4"
          codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file")
          case "$codec" in
            h264) video=(-c:v copy) ;;
            hevc) video=(-c:v copy -tag:v hvc1) ;;
            *) video=(-c:v libx264 -crf 20 -preset medium -pix_fmt yuv420p) ;;
          esac
          echo "$file ($codec) -> $output"
          ffmpeg -nostdin -hide_banner -loglevel error -stats -n -i "$file" -map 0:v:0 -map 0:a? \
            "''${video[@]}" -c:a aac -b:a 192k -movflags +faststart "$output"
        done
      '';
  };
in {
  options.programs.davinci-resolve = {
    enable = lib.options.mkEnableOption "Davinci Resolve";

    package = lib.mkPackageOption pkgs "davinci-resolve" {
      example = "pkgs.unstable.davinci-resolve-studio";
    };

    aacRepair = {
      enable = lib.options.mkEnableOption ''
        a user service that remuxes AAC audio in the Media Pool to PCM and
        relinks the clips. Requires external scripting set to Local in
        Resolve Studio's preferences'';

      directory = mkOption {
        type = types.str;
        default = "${config.xdg.dataHome}/DaVinciResolve/AAC";
        description = ''
          Persistent directory for repaired copies. Resolve projects link to
          these files, so never point it at temporary storage.
        '';
      };
    };

    mcp.enable = lib.options.mkEnableOption ''
      the davinci-resolve-mcp command, which runs the MCP server bundled with
      Resolve 21.1 and later. Requires external scripting set to Local'';
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.aacRepair.enable || cfg.package ? davinci;
        message = "programs.davinci-resolve.aacRepair needs a nixpkgs Resolve package exposing passthru.davinci";
      }
      {
        assertion = !cfg.mcp.enable || cfg.package ? davinci;
        message = "programs.davinci-resolve.mcp needs a nixpkgs Resolve package exposing passthru.davinci";
      }
    ];

    home.packages =
      [
        cfg.package
        davinci-resolve-export

        # Convert video from format to another
        pkgs.ffmpeg
      ]
      ++ lib.optional cfg.aacRepair.enable davinci-resolve-aac
      ++ lib.optional cfg.mcp.enable davinci-resolve-mcp;

    # Projects, settings, and the Studio license; the wrapper binds license/
    persist.storage.directories = [".local/share/DaVinciResolve"];

    # Downloadable AI models (Extras Download Manager) skip snapshots and backups
    persist.scratch.directories = [".local/share/DaVinciResolve/Extras"];

    systemd.user.services.davinci-resolve-aac = mkIf cfg.aacRepair.enable {
      Unit = {
        Description = "Repair AAC audio in the DaVinci Resolve Media Pool";
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${getExe davinci-resolve-aac} watch";
        Restart = "always";
        RestartSec = 10;
        Nice = 10;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
