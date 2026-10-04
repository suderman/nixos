{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  storage = config.persist.storage.path;
  hostKey = "${storage}/etc/ssh/ssh_host_ed25519_key";
  backupSend = pkgs.writeShellApplication {
    name = "dot-backup-send";
    runtimeInputs = [pkgs.btrfs-progs pkgs.coreutils pkgs.findutils pkgs.gnugrep];
    text = builtins.readFile ./backup-send.sh;
  };
in {
  # Deliberately omit the fleet-root-bearing default and personal Home Manager.
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.inputs.disko.nixosModules.disko
    ../../modules/nixos/default/configs/impermanence.nix
    ../../modules/nixos/default/configs/tmpfiles.nix
    flake.inputs.agenix.nixosModules.default
    flake.inputs.agenix-rekey.nixosModules.default
  ];

  options.dot.backupPublicKey = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Dedicated backup-host public key. Null leaves off-host backup access disabled.";
  };

  config = {
    system.stateVersion = "26.05";
    networking.hostName = "dot";
    networking.domain = "tail";
    time.timeZone = "America/Toronto";
    boot.kernelPackages = pkgs.linuxPackages;
    boot.loader.grub.configurationLimit = 5;

    # One DHCP manager. IPv6 SLAAC is provisional until Linode commissioning.
    networking.networkmanager.enable = false;
    networking.enableIPv6 = true;
    networking.tempAddresses = "disabled";
    networking.nameservers = ["1.1.1.1" "9.9.9.9"];

    age.identityPaths = [hostKey];
    age.rekey = {
      hostPubkey = builtins.readFile ./ssh_host_ed25519_key.pub;
      masterIdentities = [/tmp/id_age /tmp/id_age_];
      storageMode = "local";
      localStorageDir = flake + /secrets/nixos/dot;
      generatedSecretsDir = flake + /secrets/nixos/dot;
    };
    # No initial service secrets. In particular, no fleet hex or CA signing key.

    users.mutableUsers = false;
    users.users.root = {
      hashedPasswordFile = "${storage}/etc/dot/recovery.hash";
      openssh.authorizedKeys = flake.users.jon.openssh.authorizedKeys;
    };
    users.users.jon = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = ["wheel"];
      hashedPasswordFile = "${storage}/etc/dot/recovery.hash";
      openssh.authorizedKeys = flake.users.jon.openssh.authorizedKeys;
    };
    users.users.dot-backup = lib.mkIf (config.dot.backupPublicKey != null) {
      isSystemUser = true;
      group = "dot-backup";
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        ''restrict,command="sudo -n ${backupSend}/bin/dot-backup-send" ${config.dot.backupPublicKey}''
      ];
    };
    users.groups.dot-backup = lib.mkIf (config.dot.backupPublicKey != null) {};
    security.sudo.extraConfig = lib.mkIf (config.dot.backupPublicKey != null) ''
      Defaults:dot-backup env_keep += "SSH_ORIGINAL_COMMAND"
    '';
    security.sudo.extraRules =
      [
        {
          users = ["jon"];
          commands = [
            {
              command = "/run/current-system/sw/bin/nixos-rebuild";
              options = ["NOPASSWD"];
            }
          ];
        }
      ]
      ++ lib.optional (config.dot.backupPublicKey != null) {
        users = ["dot-backup"];
        commands = [
          {
            command = "${backupSend}/bin/dot-backup-send";
            options = ["NOPASSWD"];
          }
        ];
      };

    services.openssh = {
      enable = true;
      hostKeys = [
        {
          path = hostKey;
          type = "ed25519";
        }
      ];
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    systemd.services.dot-identity = {
      description = "Verify staged host-only identity before SSH";
      before = ["sshd.service"];
      requiredBy = ["sshd.service"];
      serviceConfig.Type = "oneshot";
      path = [pkgs.openssh pkgs.coreutils pkgs.gnugrep];
      script = ''
        set -euo pipefail
        test -s ${hostKey}
        test "$(ssh-keygen -y -f ${hostKey} | cut -d ' ' -f 1,2)" = "$(cut -d ' ' -f 1,2 ${./ssh_host_ed25519_key.pub})"
        grep -Eq '^[0-9a-f]{32}$' /etc/machine-id
        test "$(cat /etc/machine-id)" != 00000000000000000000000000000000
        test -s ${storage}/etc/dot/recovery.hash
      '';
    };
    systemd.services."serial-getty@ttyS0".enable = true;
    systemd.enableEmergencyMode = true;

    persist.storage.files = ["/etc/machine-id"];
    persist.storage.directories = [
      "/etc/dot"
      "/var/lib/tailscale"
      {
        directory = "/home/jon";
        user = "jon";
        group = "users";
        mode = "0700";
      }
    ];
    services.journald.extraConfig = ''
      Storage=persistent
      SystemMaxUse=128M
      MaxRetentionSec=7day
    '';

    services.tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = ["--accept-routes=false" "--accept-dns=false"];
    };
    networking.firewall.checkReversePath = "loose";

    # Local snapshots only. Off-host backup uses a dedicated pull credential.
    services.btrbk.instances.dot = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        snapshot_dir = "snapshots";
        snapshot_preserve_min = "6h";
        snapshot_preserve = "24h 3d";
        stream_buffer = "32m";
        volume."/mnt/main".subvolume.storage = {};
      };
    };
    systemd.services.btrbk-dot.serviceConfig = {
      TimeoutStartSec = "10min";
      MemoryMax = "256M";
      MemorySwapMax = "64M";
      TasksMax = 64;
    };

    systemd.services.dot-health = {
      description = "Check disk space and off-host backup age";
      serviceConfig.Type = "oneshot";
      path = [pkgs.coreutils pkgs.gawk];
      script = ''
        set -euo pipefail
        df -Pk /mnt/main /boot
        df -Pk /mnt/main /boot | awk 'NR > 1 && $5 + 0 >= 85 {bad=1} END {exit bad}'
        # The backup operator acknowledges a verified send, never a local snapshot.
        stamp=${storage}/etc/dot/backup-success
        test -f "$stamp"
        test "$(( $(date +%s) - $(stat -c %Y "$stamp") ))" -lt 172800
      '';
    };
    systemd.timers.dot-health = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "15min";
        OnUnitActiveSec = "1h";
      };
    };

    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      download-buffer-size = 16777216;
      http-connections = 4;
      max-substitution-jobs = 2;
      max-jobs = 1;
      cores = 1;
      trusted-users = ["root" "@wheel"];
    };
    nix.registry.nixpkgs.flake = flake.inputs.nixpkgs;
    nix.nixPath = ["nixpkgs=${flake.inputs.nixpkgs}"];
    system.autoUpgrade.enable = false;
    nix.gc.automatic = false;
    documentation.nixos.enable = false;
    environment.systemPackages = [pkgs.btrfs-progs pkgs.curl pkgs.git pkgs.jq];

    assertions = [
      {
        assertion = builtins.pathExists ./fleet-root-independent;
        message = "dot must stay outside fleet root generation and rotation";
      }
    ];
  };
}
