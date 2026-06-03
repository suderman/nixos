# programs.nf.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.opencode;
  cfgDir = ".config/nf";
in {
  options.programs.nf = {
    enable = lib.mkEnableOption "nf";
    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to multi-line .env file with API_KEY=123";
    };
  };

  config = lib.mkIf cfg.enable {
    toolchains.go.enable = true;

    # Persist the config, data and state directories
    persist.storage.directories = [cfgDir];
    persist.scratch.directories = [
      ".local/share/nf"
      ".local/state/nf"
    ];

    # Temporary alias until this program is finished being written
    home.shellAliases = {
      nf = "nix run ${config.home.homeDirectory}/src/nonfiction/nf --";
    };

    # Let agenix know about any secrets set
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      nf-env.rekeyFile = cfg.apiKeys;
    };

    # Place .env in ~/.config/nf
    systemd.user.services.nf-env = let
      # Encrypted API keys
      # DNSIMPLE_TOKEN=
      # KINSTA_API_KEY=
      # LINODE_TOKEN=
      # NF_PASSWORD_SALT=
      nfEnv =
        if cfg.apiKeys != null
        then config.age.secrets.nf-env.path
        else "/dev/null";
      nfDir = "${config.home.homeDirectory}/${cfgDir}";
    in {
      Unit = {
        Description = "Generate nf .env";
        Requires = lib.mkIf (cfg.apiKeys != null) ["agenix.service"];
        After = lib.mkIf (cfg.apiKeys != null) ["agenix.service"];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.self.mkScript {
          text =
            # sh
            ''
              mkdir -p "${nfDir}"
              if [ -r "${nfEnv}" ]; then
                cat "${nfEnv}" > "${nfDir}/.env"
              fi
              chmod 600 "${nfDir}/.env"
            '';
        };
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
