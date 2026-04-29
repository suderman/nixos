{
  lib,
  pkgs,
  ...
}: {
  systemd.user.timers.nixos-repo-sync = {
    Unit.Description = "Best-effort sync of /etc/nixos";
    Timer = {
      OnCalendar = "03:15";
      RandomizedDelaySec = "30min";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };

  systemd.user.services.nixos-repo-sync = {
    Unit.Description = "Best-effort sync of /etc/nixos";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "/etc/nixos";
      ExecStart = lib.getExe (pkgs.writeShellApplication {
        name = "nixos-repo-sync";
        runtimeInputs = [pkgs.git];
        text = ''
          if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "Skipping /etc/nixos sync: not a git work tree"
            exit 0
          fi

          if ! git diff --quiet || ! git diff --cached --quiet; then
            echo "Skipping /etc/nixos sync: repository has local changes"
            exit 0
          fi

          if [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
            echo "Skipping /etc/nixos sync: repository has untracked files"
            exit 0
          fi

          branch="$(git symbolic-ref --quiet --short HEAD || true)"
          if [[ -z "$branch" ]]; then
            echo "Skipping /etc/nixos sync: detached HEAD"
            exit 0
          fi

          git fetch --quiet origin "$branch"
          git pull --ff-only --quiet origin "$branch"
        '';
      });
    };
  };

  # Custom user service
  systemd.user.services.foobar-hm = {
    Unit = {
      Description = "Foobar Home-Manager";
      After = ["graphical-session.target"];
      Requires = ["graphical-session.target"];
    };
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      Environment = ''"FOO=bar"'';
      ExecStart = with pkgs;
        writeShellScript "foobar-hm" ''
          PATH=${lib.makeBinPath [coreutils]}
          touch /tmp/foobar-hm.txt
          date >>/tmp/foobar-hm.txt
        '';
    };
  };
}
