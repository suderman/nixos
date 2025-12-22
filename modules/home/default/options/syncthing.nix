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
in {
  config = mkIf cfg.enable {
    services.syncthing = {
      tray.enable = false;
      package = pkgs.unstable.syncthing;

      # Allow devices & folders to be managed via webui
      overrideDevices = false;
      overrideFolders = false;

      # Automatically connect these devices
      settings.devices = let
        devices = {
          kit.id = "ARS5AY4-HVAKVHE-5IIYPX5-DZORQBR-UHYYQIQ-ON7JMUI-2PPI5IS-EW3IKAZ";
          cog.id = "PPAG274-GPYIMXP-5CY62WF-B4QNQCP-5KWIT3Y-RG6OCJG-PRQDBP3-HW5VBQY";
          phone.id = "U3OH2WI-YRTLO2A-UNNTEPG-QSGAAQH-VNEEQJK-A6TTVHP-KM7KX7L-Q3M5KQV";
        };
      in
        builtins.mapAttrs
        (_: device: device // {autoAcceptFolders = true;})
        (builtins.removeAttrs devices [config.networking.hostName]);

      # Automatically include XDG folders marked enabled for sync
      settings.folders =
        mapAttrs
        (_: folder: {path = "~/${folder.path}";})
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
