{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.services.asana-org;
  headingArgs = lib.concatMapStringsSep " " (heading: "--org-heading ${lib.escapeShellArg heading}") cfg.orgHeading;
  asana-org = perSystem.self.mkScript {
    name = "asana-org";
    text = ''
      exec ${lib.getExe pkgs.python3} ${./asana-org.py} \
        --org-file ${lib.escapeShellArg cfg.orgFile} \
        ${headingArgs} \
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
      default = "${config.home.homeDirectory}/org/todo.org";
      description = "Org file that receives the managed Asana task block";
    };

    orgHeading = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["Asana"];
      example = [
        "work"
        "Asana"
      ];
      description = "Exact Org heading path under which tasks are written";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.orgFile != "";
        message = "services.asana-org.orgFile must not be empty";
      }
      {
        assertion = cfg.orgHeading != [] && lib.all (heading: heading != "") cfg.orgHeading;
        message = "services.asana-org.orgHeading must contain at least one non-empty heading";
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
