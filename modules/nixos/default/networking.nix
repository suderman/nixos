{
  config,
  lib,
  hostName,
  flake,
  ...
}: let
  inherit (builtins) attrNames attrValues filter;
  inherit (lib) filterAttrs hasPrefix mkDefault mkOption naturalSort types unique;
in {
  # Extra options for each host
  options.networking = {
    hostNames = mkOption {
      description = "All hostnames this host can be reached at";
      type = with types; listOf str;
      default = [];
    };

    address = mkOption {
      description = "Primary IP address this host can be reached at";
      type = with types; str;
      default = "127.0.0.1";
    };

    addresses = mkOption {
      description = "All IP addresses this host can be reached at";
      type = with types; listOf str;
      default = [];
    };
  };

  config = {
    networking = {
      # Derive primary hostName from blueprint ./hosts/dir
      hostName = hostName;

      # All the hostNames this host can be reached with
      hostNames =
        filter
        (name: hasPrefix hostName name)
        (attrNames flake.networking.records);

      # Primary IP address from flake's zones
      address = flake.networking.records.${hostName} or "127.0.0.1";

      # All the IP addresses this host can be reached with
      addresses =
        ["127.0.0.1"]
        ++ unique (naturalSort (attrValues (
          filterAttrs (name: ip: hasPrefix hostName name) flake.networking.records
        )));
    };

    # Set your time zone
    time.timeZone = mkDefault "America/Edmonton";

    # Editable hosts file
    system.activationScripts.hosts = let
      inherit (config.networking) hostName domain;
      source = "/mnt/main/storage/etc/hosts";
      target = "/etc/hosts";
    in {
      text =
        # bash
        ''
          mkdir -p $(dirname ${source}) $(dirname ${target})
          if [[ ! -s ${source} ]]; then
            {
              echo "127.0.0.1 localhost"
              echo "::1 localhost"
              echo "127.0.0.2 ${hostName}.${domain} ${hostName}"
            } >"${source}"
          fi
          chmod 644 ${source}
          ln -sf ${source} ${target}
        '';
      deps = ["etc"];
    };

    # NetworkManager
    networking.networkmanager.enable = true;

    # Add config's users to the networkmanager group
    users.users = flake.lib.extraGroups config ["networkmanager"];

    # Persist connections after reboots
    persist.storage.directories = ["/etc/NetworkManager/system-connections"];
  };
}
