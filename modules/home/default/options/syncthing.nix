{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.syncthing;
  inherit (lib) mkIf mkForce mapAttrs filterAttrs;
  toPort = port: toString (port + config.home.portOffset);

  syncPort = 22000; # tcp/udp
  webguiPort = 8384; # tcp

  # All peer device ids (skipping this system)
  # { cog = "PPAG274-GPYIMXP-5CY62WF-B4QNQCP-5KWIT3Y-RG6OCJG-PRQDBP3-HW5VBQY"; }
  deviceIds = builtins.removeAttrs cfg.deviceIds [config.networking.hostName];
in {
  options.services.syncthing.deviceIds = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      tray.enable = false;
      package = pkgs.unstable.syncthing;

      # Allow devices & folders to be managed via webui
      overrideDevices = false;
      overrideFolders = false;

      # Automatically connect these devices
      settings.devices =
        builtins.mapAttrs (_: id: {
          inherit id;
          autoAcceptFolders = true;
        })
        deviceIds;

      # Automatically include XDG folders marked enabled for sync
      settings.folders =
        mapAttrs
        (_: folder: {
          path = "~/${folder.path}";
          devices = builtins.attrNames deviceIds;
        })
        (filterAttrs (_: d: (d.enable && d.sync)) config.home.directories);

      # Unique listen ports per user on host
      settings.listenAddresses = [
        "tcp://0.0.0.0:${toPort syncPort}"
        "quic://0.0.0.0:${toPort syncPort}"
        "dynamic+https://relays.syncthing.net/endpoint"
      ];
    };

    # Update flags for v2 in unstable
    systemd.user.services.syncthing.Service.ExecStart = let
      syncthingArgs =
        [
          "${lib.getExe cfg.package}"
          "serve"
          "--no-browser"
          "--no-restart"
          "--no-upgrade"
          "--gui-address=http://0.0.0.0:${toPort webguiPort}"
        ]
        ++ cfg.extraOptions;
    in
      mkForce (lib.escapeShellArgs syncthingArgs);

    # Persist state across reboots
    persist.storage.directories = [".local/state/syncthing"];

    # Drop .stignore template in each synced folder
    tmpfiles = rec {
      directories =
        map
        (n: builtins.baseNameOf n)
        (builtins.attrValues (mapAttrs (_: v: v.path) cfg.settings.folders));
      files =
        map (folder: {
          target = "${folder}/.stignore";
          source = "${config.xdg.configHome}/syncthing/stignore";
        })
        directories;
    };

    # Syncthing ignore template
    xdg.configFile."syncthing/stignore".text =
      # c
      ''
        // OS-generated files (safe to delete / ignore)
        (?d).DS_Store
        (?d).AppleDouble
        (?d).apdisk
        (?d).localized
        (?d).Icon?
        (?d).Spotlight-V100
        (?d).Trashes
        (?d).fseventsd
        (?d).TemporaryItems
        (?d).DocumentRevisions-V100
        (?d).directory
        (?d).nfs*
        (?d)lost+found
        (?d).local/share/Trash
        (?d).Trash-*
        (?d).trash
        (?d).Trash
        (?d)desktop.ini
        (?d)Thumbs.db
        (?d)Thumbs.db:encryptable
        (?d)ehthumbs.db
        (?d)$RECYCLE.BIN
        (?d)System Volume Information
        *.lnk
        (?d)@eaDir

        // Syncthing-local housekeeping (don’t sync between devices)
        (?d).stversions
        (?d).stversions/*

        // App / editor-generated junk
        .dropbox
        .dropbox.attr
        *.part
        *.crdownload
        ~$*
        .idea
        .vscode

        // Version control metadata (don’t sync repos)
        .git
        .gitmodules
        .gitattributes
        .hg
        .svn
        .bzr
        .pijul
        .jj
        .fossil-settings
        node_modules

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
