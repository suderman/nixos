# services.ytdl-sub.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.ytdl-sub;
  subscriptionsFile = "/var/lib/ytdl-sub/subscriptions.yaml";
  configFile = (pkgs.formats.yaml {}).generate "config.yaml" cfg.instances.youtube.config;
in {
  options.services.ytdl-sub.enable = lib.mkEnableOption "YouTube subscriptions for Jellyfin";

  config = lib.mkIf cfg.enable {
    services.ytdl-sub = {
      group = lib.mkDefault "media";
      instances.youtube = {
        enable = true;
        schedule = lib.mkDefault "*-*-* 00/6:00:00";
        readWritePaths = ["/media/youtube/video"];
        config = {
          configuration = {
            # Upstream uses /run, a tmpfs too small for video downloads.
            working_directory = lib.mkForce "/var/cache/ytdl-sub";
            umask = "002";
          };
          presets.YouTube = {
            preset = ["Jellyfin TV Show by Date" "Max 1080p"];
            overrides.tv_show_directory = "/media/youtube/video";
            # A download window, not retention. Existing media is never aged out.
            date_range = {
              after = "today-30days";
              # Playlists need not be ordered by upload date.
              breaks = false;
            };
            ytdl_options = {
              format_sort = ["vcodec:h264" "acodec:aac"];
              merge_output_format = "mp4";
            };
            chapters = {
              sponsorblock_categories = ["sponsor"];
              remove_sponsorblock_categories = ["sponsor"];
            };
          };
        };
      };
    };

    persist.storage.directories = [
      {
        directory = "/var/lib/ytdl-sub";
        user = cfg.user;
        group = cfg.group;
        mode = "0750";
      }
    ];

    systemd.services.ytdl-sub-youtube = {
      unitConfig.RequiresMountsFor = ["/var/lib/ytdl-sub" "/media"];
      serviceConfig = {
        ExecCondition = "${pkgs.coreutils}/bin/test -s ${subscriptionsFile}";
        # Upstream accepts only store-generated subscriptions, not a runtime file.
        ExecStart = lib.mkForce "${lib.getExe cfg.package} --config ${configFile} sub ${subscriptionsFile}";
        CacheDirectory = "ytdl-sub";
        UMask = "0002";
      };
    };
  };
}
