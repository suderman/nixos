{
  lib,
  pkgs,
  ...
}: let
  srcDir = "/mnt/main/storage/home/jon";
  dstDir = "/home/bot";

  mounts = [
    {
      src = "${srcDir}/org";
      dst = "${dstDir}/org";
      rw = true;
    }
    {
      src = "${srcDir}/.local/share/calendars";
      dst = "${dstDir}/.local/share/calendars";
      rw = true;
    }
    {
      src = "${srcDir}/.local/share/contacts";
      dst = "${dstDir}/.local/share/contacts";
      rw = true;
    }
    {
      src = "${srcDir}/.local/share/mail";
      dst = "${dstDir}/.local/share/mail";
      rw = false;
    }
  ];

  rwMounts = builtins.filter (m: m.rw) mounts;
in {
  # Bind mount select jon directories in bot's home
  fileSystems = lib.listToAttrs (map (m: {
      name = m.dst;
      value = {
        device = m.src;
        fsType = "none";
        options = ["bind"] ++ lib.optional (!m.rw) "ro";
        depends = ["/mnt/main/storage"];
      };
    })
    mounts);

  # Attempt to set perms and ACLs to let both users access these files
  systemd.services.bind-mounts-perms = {
    description = "Fix perms and ACLs for bot shared trees";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    unitConfig.RequiresMountsFor = map (m: m.src) rwMounts;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [coreutils findutils acl];

    script = ''
      set -eu
      ${lib.concatMapStringsSep "\n" (m: ''
          chgrp -R users "${m.src}"
          find "${m.src}" -type d -exec chmod 2770 {} +
          find "${m.src}" -type f -exec chmod 0660 {} +
          setfacl -R -m d:u::rwx,d:g::rwx,d:o::--- "${m.src}"
        '')
        rwMounts}
    '';
  };

  # Workaround khal/khard tightening permissions on a file the user edits
  systemd.services.fix-shared-cal-perms = {
    description = "Restore group rw permissions on shared calendar/contact files";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "fix-cal-perms" ''
        find ${srcDir}/.local/share/calendars \
             ${srcDir}/.local/share/contacts \
          -type f \( -name "*.ics" -o -name "*.vcf" \) \
          ! -perm -g+rw \
          -exec chmod g+rw {} +
      '';
    };
  };

  # Trigger workaround when one of these directory paths are touched
  systemd.paths.fix-shared-cal-perms = {
    wantedBy = ["multi-user.target"];
    pathConfig = {
      PathChanged = [
        "${srcDir}/.local/share/contacts/Personal"
        "${srcDir}/.local/share/contacts/Shared"
        "${srcDir}/.local/share/calendars/Family"
        "${srcDir}/.local/share/calendars/Personal"
        "${srcDir}/.local/share/calendars/Wife"
        "${srcDir}/.local/share/calendars/Work"
      ];
      Unit = "fix-shared-cal-perms.service";
    };
  };

  # Also trigger workaround every 15 minutes just in case
  systemd.timers.fix-shared-cal-perms = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
      Unit = "fix-shared-cal-perms.service";
    };
  };
}
