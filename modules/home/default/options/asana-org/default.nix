{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.services.asana-org;
  asana-org = perSystem.self.mkScript {
    name = "asana-org";
    text = ''
      exec ${lib.getExe pkgs.python3} ${./asana-org.py} \
        --org-file ${lib.escapeShellArg cfg.orgFile} \
        --token-file ${lib.escapeShellArg config.age.secrets.asana-org-token.path} \
        --workspace ${lib.escapeShellArg cfg.workspace} "$@"
    '';
  };
in {
  options.services.asana-org = {
    enable = lib.mkEnableOption "Asana to Org task sync";

    secret = lib.mkOption {
      type = lib.types.path;
      description = "Age-encrypted file containing only the Asana personal access token";
    };

    workspace = lib.mkOption {
      type = lib.types.strMatching "[0-9]+";
      description = "Asana workspace gid";
    };

    orgFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/org/asana.org";
      description = "Dedicated Org file managed by the Asana task sync";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.orgFile != "";
        message = "services.asana-org.orgFile must not be empty";
      }
    ];

    age.secrets.asana-org-token.rekeyFile = cfg.secret;

    home.packages = [asana-org];

    systemd.user = {
      services.asana-org = {
        Unit = {
          Description = "Mirror Asana My Tasks into Org";
          Requires = ["agenix.service"];
          After = ["agenix.service"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe asana-org;
        };
      };

      timers.asana-org = {
        Unit.Description = "Mirror Asana My Tasks into Org every 15 minutes";
        Timer = {
          OnCalendar = "*:0/15";
          Persistent = true;
          Unit = "asana-org.service";
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
