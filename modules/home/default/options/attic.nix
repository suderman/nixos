{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.attic-cache;
  sub = config.home.username;
  hostName = "${osConfig.services.attic.name}.${osConfig.networking.hostName}";
in {
  options.services.attic-cache = {
    enable = lib.mkEnableOption "nightly building of host closures and pushing them to Attic";
    hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "nixosConfigurations hosts to build from /etc/nixos and push to the main cache.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf osConfig.services.attic.enable {
      persist.storage.directories = [".config/attic"];

      home.packages = [
        (pkgs.self.mkScript {
          name = "attic-init";
          text =
            # sh
            ''
              TOKEN="$(
                cd / &&
                sudo atticd-atticadm make-token \
                  --sub "${sub}" \
                  --validity "120 months" \
                  --pull '*' \
                  --push '*' \
                  --delete '*' \
                  --create-cache '*' \
                  --configure-cache '*' \
                  --configure-cache-retention '*' \
                  --destroy-cache '*'
              )"
              attic login local https://${hostName} $TOKEN --set-default
              attic cache create main
              attic cache info main
            '';
        })
      ];
    })

    (lib.mkIf cfg.enable {
      systemd.user.services.attic-cache = {
        Unit = {
          Description = "Build host closures and push them to Attic";
          # Pull main first; hosts upgrade from github:suderman/nixos, not this checkout.
          Wants = ["nixos-repo-sync.service"];
          After = ["nixos-repo-sync.service"];
        };
        Service = {
          Type = "oneshot";
          WorkingDirectory = "/etc/nixos";
          ExecStart = lib.getExe (pkgs.self.mkScript {
            name = "attic-cache";
            path = [pkgs.git pkgs.self.nixos];
            text =
              # bash
              ''
                # Build only what hosts will fetch: a clean checkout at origin/main.
                if ! git diff --quiet HEAD; then
                  echo "Skipping attic-cache: /etc/nixos has uncommitted changes"
                  exit 0
                fi

                git fetch --quiet origin main
                if [[ $(git rev-parse HEAD) != $(git rev-parse origin/main) ]]; then
                  echo "Skipping attic-cache: /etc/nixos HEAD is not origin/main"
                  exit 0
                fi

                # One call per host, since nixos cache stops at its first failure.
                failed=()
                for host in ${lib.escapeShellArgs cfg.hosts}; do
                  nixos cache "$host" || failed+=("$host")
                done

                if [[ ''${#failed[@]} -gt 0 ]]; then
                  echo "attic-cache: failed hosts: ''${failed[*]}" >&2
                  exit 1
                fi
              '';
          });
        };
      };

      # Two hours before system.autoUpgrade, which starts at 04:00 with up to 45 minutes of delay.
      systemd.user.timers.attic-cache = {
        Unit.Description = "Build host closures and push them to Attic nightly";
        Timer = {
          OnCalendar = "*-*-* 02:00:00";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    })
  ];
}
