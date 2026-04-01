{pkgs, ...}: let
  persistDir = "/mnt/main/storage";
in {
  # Bind jon's ~/org to bot's ~/org
  fileSystems."/home/bot/org" = {
    device = "${persistDir}/home/jon/org";
    fsType = "none";
    options = ["bind"];
    depends = [persistDir];
  };

  # Ensure valid permissions so it can be shared with bot
  systemd.services.fix-shared-jon-org-perms = {
    description = "Restore ownership, modes, and ACLs on shared org files";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "fix-shared-jon-org-perms" ''
        set -euo pipefail

        root=${persistDir}/home/jon/org
        setfacl=${pkgs.acl}/bin/setfacl

        chown -R jon:users "$root"

        # Traditional ownership + mode bits
        find "$root" -type d -exec chmod 2770 {} +
        find "$root" -type f -exec chmod 0660 {} +

        # Access ACLs for existing paths
        $setfacl -R -m u:jon:rwx,g:users:rwx,o::--- "$root"

        # Default ACLs for newly created paths under directories
        $setfacl -R -d -m u:jon:rwx,g:users:rwx,o::--- "$root"
      '';
    };
  };

  # Run the above very 15 minutes
  systemd.timers.fix-shared-jon-org-perms = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
      Unit = "fix-shared-jon-org-perms.service";
    };
  };

  # Alias jon's opencode with real https certificate (to satisfy P4OC)
  services.traefik.proxy."code.suderman.org" = {
    url = "https://opencode-jon.kit";
    public = false;
    tls = {
      certresolver = "resolver-dns";
      domains = [
        {
          main = "code.suderman.org";
          sans = "*.code.suderman.org";
        }
      ];
    };
  };

  # Alias jon's bot's openclaw with real https certificate
  services.traefik.proxy."claw.suderman.org" = {
    url = "https://openclaw-bot.kit";
    public = false;
    tls = {
      certresolver = "resolver-dns";
      domains = [
        {
          main = "claw.suderman.org";
          sans = "*.claw.suderman.org";
        }
      ];
    };
  };
}
