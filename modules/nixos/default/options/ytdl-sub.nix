# services.ytdl-sub.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.ytdl-sub;
  hasSubscriptions = builtins.removeAttrs cfg.instances.youtube.subscriptions ["__preset__"] != {};
in {
  options.services.ytdl-sub.enable = lib.mkEnableOption "YouTube subscriptions for Jellyfin";

  config = lib.mkIf cfg.enable {
    services.ytdl-sub = {
      group = lib.mkDefault "media";
      instances.youtube = {
        enable = true;
        schedule = lib.mkDefault "*-*-* 00/6:00:00";
        readWritePaths = lib.optional hasSubscriptions "/media/YouTube";
        config = {
          configuration = {
            # Upstream uses /run, a tmpfs too small for video downloads.
            working_directory = lib.mkForce "/var/cache/ytdl-sub";
            umask = "002";
          };
          presets.YouTube = {
            preset = ["Jellyfin TV Show by Date" "Max 1080p"];
            overrides.tv_show_directory = "/media/YouTube";
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
        subscriptions.__preset__.preset = "YouTube";
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
      # An empty configuration needs neither Lux nor YouTube.
      unitConfig.RequiresMountsFor = ["/var/lib/ytdl-sub"] ++ lib.optional hasSubscriptions "/media";
      serviceConfig = {
        ExecCondition = "${pkgs.coreutils}/bin/${
          if hasSubscriptions
          then "true"
          else "false"
        }";
        CacheDirectory = "ytdl-sub";
        UMask = "0002";
      };
    };
  };
}
