{
  config,
  flake,
  lib,
  pkgs,
  ...
}: {
  imports =
    [
      flake.homeModules.default
      flake.homeModules.desktop.hyprland
      flake.homeModules.users.jon
    ]
    ++ flake.lib.ls ./.;

  # The data disk supplies this bind mount, not main-disk impermanence storage.
  home.directories.DATA.persist = lib.mkForce null;

  # Only kit writes the shared appearance file; other machines consume it.
  programs.emacs.exportStyle = true;

  # Only kit archives old finished Org headings, so Syncthing sees one writer.
  programs.emacs.archiveOrg = true;

  # Programs
  programs.davinci-resolve = {
    enable = true;
    package = pkgs.unstable.davinci-resolve-studio;
    # Repaired copies sit beside Resolve's CacheClip on the backed-up data disk.
    aacRepair = {
      enable = true;
      directory = "${config.home.homeDirectory}/${config.home.directories.DATA.path}/media/AAC";
    };
    mcp.enable = true;
  };
  programs.sparrow.enable = true;
  programs.zwift.enable = true;
  programs.nf.enable = true;
  programs.buzz.enable = true;

  # Agents
  programs.agents.enable = true;
  programs.claude-code.enable = true;
  programs.opencode.enable = true;
  programs.pi-coding-agent.enable = true;
  programs.mmx-cli.enable = true;

  # Gaming
  programs.steam.enable = true;
  programs.dolphin-emu.enable = true;
  programs.citron.enable = false; # Disabled until the pinned AppImage hash is repaired.
  programs.eden.enable = true;
  programs.ryubing.enable = true;
  programs.prismlauncher.enable = true;

  # Music
  services.mpd.enable = true; # music daemon
  programs.ncmpcpp.enable = true; # old client
  programs.rmpc.enable = true; # new client
  programs.projectm.enable = true; # visualizer

  # User services
  services.recall = {
    enable = true;
    bluebubbles.enable = true;
    nightly = {
      enable = true;
      author = "Jon Suderman";
    };
  };
  services.handy.enable = true;
  services.syncthing.enable = true;
  services.attic-cache = {
    enable = true;
    hosts = ["cog" "eve" "hub" "kit" "lux" "pow" "wit"];
  };
  services.withings-sync = {
    enable = false;
    secret = ./withings-sync.age;
  };
  services.garmin = {
    enable = false;
    deviceId = "091e_4cda_0000cb7d522d";
    dataDir = "${config.home.homeDirectory}/fenix";
  };

  # User web server
  services.caddy.enable = true;

  # Email, calendars, contacts
  accounts.enable = true;
}
