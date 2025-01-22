{ config, lib, pkgs, ... }: {

  # Aliases 
  home.shellAliases = with pkgs; rec {
    df = "df -h";
    du = "du -ch --summarize";
    ls = "lsd";
    la = "${ls} -A";
    l = "${ls} -Alh";
    map = "xargs -n1";
    maplines = "xargs -n1 -0";
    grep = "rg";
    tl = "tldr";
    isd = "nix run github:isd-project/isd"; # manage systemd units
  };

  home.packages = with pkgs; [ 
    fetchgithub 
  ];

  programs.btop = {
    enable = true;
    package = pkgs.btop.overrideAttrs (prev: rec {
      cmakeFlags = (prev.cmakeFlags or []) ++ [
        # "-DBTOP_RSMI_STATIC=ON"
        # "-DBTOP_GPU=ON"
        "GPU_SUPPORT=true"
      ];
    });
  };

  programs.zoxide.enable = true;

  programs.less.enable = true;
  programs.lesspipe.enable = true;

  programs.ripgrep = {
    enable = true;
    package = pkgs.ripgrep-all;
    arguments = [
      "--max-columns=150"
      "--max-columns-preview"
      "--colors=line:style:bold" # pretty
      "--smart-case"
      "--hidden" # search hidden files/directories
      "--glob=!package-lock.json"
      "--glob=!node_modules/*" 
      "--glob=!.git/*"
      "--glob=!yarn.lock"
      "--glob=!.yarn/*"
      "--glob=!dist/*" 
      "--glob=!build/*"
      "--glob=!.cache/*" 
      "--glob=!.vscode/*"
    ];
  };
  
  # services.mopidy = {
  #   enable = true;
  #   extensionPackages = with pkgs; [
  #     # mopidy-local
  #     mopidy-jellyfin
  #     mopidy-bandcamp
  #     mopidy-soundcloud
  #     # mopidy-youtube
  #     # mopidy-podcast
  #     mopidy-mpd
  #     mopidy-mpris
  #   ];
  #   settings = {
  #     audio.output = "autoaudiosink";
  #     mpris.enabled = true;
  #     mpd = {
  #       enabled = true;
  #       hostname = "0.0.0.0"; 
  #       port = 6600; 
  #     };
  #     m3u = {
  #       enabled = true;
  #       default_encoding = "UTF-8";
  #       default_extension = ".m3u8";
  #       playlists_dir = "${config.xdg.userDirs.music}/Playlists";
  #     };
  #     # youtube = {
  #     #   enabled = true;
  #     #   allow_cache = true;
  #     #   threads_max = 16;
  #     #   channel_id = "_3LN2xxmK9CMYFh3WrxRVQ";
  #     # };
  #     jellyfin = {
  #       enabled = true;
  #       libraries = [ "Music" ];
  #       albumartistsort = true;
  #       album_format = "{Name}";
  #     };
  #     file = {
  #       media_dirs = [ "$XDG_MUSIC_DIR|Music" ];
  #       follow_symlinks = true;
  #       excluded_file_extensions = [ ".html" ".zip" ".jpg" ".jpeg" ".png" ];
  #     };
  #     logging = {
  #       color = true;
  #       console_format = "%(levelname)-8s %(message)s";
  #       debug_format = "%(levelname)-8s %(asctime)s [%(process)d:%(threadName)s] %(name)s\n  %(message)s";
  #       debug_file = "$XDG_CONFIG_DIR/mopidy/mopidy.log";
  #     };
  #   };
  #   extraConfigFiles = [ "${config.xdg.configHome}/mopidy/secrets.conf" ];
  #
  # };
  #
  # age.secrets.mopidy.file = config.secrets.files.mopidy;
  #
  # home.activation.mopidy = let 
  #   # playlistsDir = config.services.mopidy.settings.m3u.playlists_dir;
  #   playlistsDir = "${config.xdg.configHome}/mopidy";
  #   extraConfig = builtins.elemAt config.services.mopidy.extraConfigFiles 0;
  # in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   $DRY_RUN_CMD mkdir -p ${playlistsDir}
  #   $DRY_RUN_CMD cat ${config.age.secrets.mopidy.path} > ${extraConfig}
  # '';

}
