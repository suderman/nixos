{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.syncthing;
  inherit (config.home) portOffset;
  inherit (lib) mkIf mkForce mapAttrs filterAttrs;

  syncPort = 22000; # tcp/udp
  webguiPort = 8384; # tcp
in {
  config = mkIf cfg.enable {
    services.syncthing = {
      tray.enable = false;

      # v2 available in unstable
      package = pkgs.unstable.syncthing;

      # Unique listen ports per user on host
      extraOptions = ["--gui-address=http://0.0.0.0:${toString (webguiPort + portOffset)}"];

      # We'll manually manage devices
      overrideDevices = false;

      # Automatically include XDG folders marked enabled for sync
      settings.folders = mapAttrs 
        (_: folder: {path = "~/${folder.path}";}) 
        (filterAttrs (_: d: (d.enable && d.sync)) config.home.directories);

      # Unique listen ports per user on host
      settings.listenAddresses = [
        "tcp://0.0.0.0:${toString (syncPort + portOffset)}"
        "quic://0.0.0.0:${toString (syncPort + portOffset)}"
        "dynamic+https://relays.syncthing.net/endpoint"
      ];
    };

    # Update flags for v2 in unstable
    systemd.user.services.syncthing.Service.ExecStart = let
      syncthingArgs = [
        "${lib.getExe cfg.package}"
        "--no-browser"
        "--no-restart"
        "--no-upgrade"
        "--logflags=0"
      ] ++ cfg.extraOptions;
     in mkForce (lib.escapeShellArgs syncthingArgs);

    # Persist state across reboots
    persist.scratch.directories = [".local/state/syncthing"];

    # Drop .stignore template in each synced folder
    tmpfiles = rec {
      directories = map 
        (n: builtins.baseNameOf n) 
        (builtins.attrValues (mapAttrs (_: v: v.path) cfg.settings.folders));
      files = map (folder: {
        target = "${folder}/.stignore";
        source = "${config.xdg.configHome}/syncthing/stignore";
      }) directories;
    };

    # Syncthing ignore template
    xdg.configFile."syncthing/stignore".text = 
      # c
      ''
      // OS-generated files
      (?d).DS_Store
      (?d).AppleDouble
      (?d).apdisk
      (?d).localized
      (?d).Icon?
      (?d).Spotlight-V100
      (?d).Trashes
      (?d).fseventsd
      (?d).TemporaryItems
      (?d).directory
      (?d).nfs*
      (?d)lost+found
      (?d).local/share/Trash
      (?d).Trash-*
      (?d)desktop.ini
      (?d)Thumbs.db
      (?d)Thumbs.db:encryptable
      (?d)ehthumbs.db
      (?d)$RECYCLE.BIN
      (?d)System Volume Information
      *.lnk
      (?d)@eaDir

      // App-generated files
      .dropbox
      .dropbox.attr
      *.part
      *.crdownload
      ~$*
      .idea/
      .vscode/

      // Temp and backup
      *.tmp
      *.temp
      *.bak
      *.old
      *~
      *._mp
      *.syd
      *.chk
      *.dmp
      *.nch
      .*.sw[a-p]
      *.*.sw[a-p]

      // Forbidden FAT/Windows characters
      *["<>:|?*]*

      // Trailing space or dot
      * .
      *.
    '';
  };
}
