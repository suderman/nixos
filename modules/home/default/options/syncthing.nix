{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.syncthing;
  inherit (lib) filterAttrs mapAttrs mkForce mkIf;
  toPort = port: toString (port + config.home.portOffset);

  syncPort = 22000; # tcp/udp
  webguiPort = 8384; # tcp

  # All peer device ids (skipping this system)
  # { cog = "PPAG274-GPYIMXP-5CY62WF-B4QNQCP-5KWIT3Y-RG6OCJG-PRQDBP3-HW5VBQY"; }
  deviceIds = builtins.removeAttrs cfg.deviceIds [config.networking.hostName];
  syncFolders = filterAttrs (_: folder: folder.enable && folder.sync) config.home.directories;
  folderDevices = folder:
    builtins.filter
    (name: name != config.networking.hostName)
    (
      if folder.syncDevices == null
      then builtins.attrNames cfg.deviceIds
      else folder.syncDevices
    );
  ignoreFile = config.xdg.configFile."syncthing/stignore".source;
in {
  options.services.syncthing.deviceIds = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
  };

  config = mkIf cfg.enable {
    assertions =
      lib.mapAttrsToList (name: folder: let
        unknownDevices =
          builtins.filter
          (device: !(builtins.hasAttr device cfg.deviceIds))
          (
            if folder.syncDevices == null
            then []
            else folder.syncDevices
          );
      in {
        assertion = unknownDevices == [];
        message = "Syncthing folder ${name} references unknown devices: ${lib.concatStringsSep ", " unknownDevices}";
      })
      syncFolders;

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
          autoAcceptFolders = false;
        })
        deviceIds;

      # Automatically include XDG folders marked enabled for sync
      settings.folders =
        mapAttrs
        (_: folder: {
          path = "~/${folder.path}";
          devices = folderDevices folder;
        })
        syncFolders;

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

    # Syncthing does not sync .stignore, so install a regular copy for every folder.
    home.activation.syncthingIgnoreFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (_: folder: let
          target = "${config.home.homeDirectory}/${folder.path}/.stignore";
        in ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm0644 \
            ${lib.escapeShellArg ignoreFile} \
            ${lib.escapeShellArg "${target}.tmp"}
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv -fT \
            ${lib.escapeShellArg "${target}.tmp"} \
            ${lib.escapeShellArg target}
        '')
        syncFolders)}
    '';

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
