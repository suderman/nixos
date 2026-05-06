{
  config,
  lib,
  flake,
  ...
}: let
  inherit (builtins) filter listToAttrs;
  inherit (lib) head nameValuePair;
  inherit (config.home) username;

  # Raw per-zone address maps from `zones/*/default.nix`, e.g.
  # {
  #   home = { hub = "10.1.0.4"; ...; };
  #   tail = { hub = "100.x.x.x"; ...; };
  # }
  inherit (flake.networking) zones;
  zoneNames = builtins.attrNames zones;

  # NixOS hosts declared in `hosts/<name>/configuration.nix` that also have a
  # primary record in `flake.networking.records`. Exclude `iso` because it is an
  # installer image, not an SSH target.
  flakeHosts =
    filter
    (host: host != "iso" && builtins.hasAttr host flake.networking.records)
    (flake.lib.ls {
      path = flake + /hosts;
      dirsWith = ["configuration.nix"];
      dirsExcept = [];
      asPath = false;
    });

  # Flatten all zone records into a list of `{ name, zone }` pairs so we can
  # generate both fully qualified aliases (`hub.home`) and short aliases
  # (`logos`) from one source of truth.
  zoneRecords = builtins.concatLists (
    map
    (zone:
      map (name: {inherit name zone;}) (builtins.attrNames zones.${zone}))
    zoneNames
  );

  # All zones where a given record name exists. Used to decide whether a short
  # alias is unambiguous.
  zoneNamesFor = name: filter (zone: builtins.hasAttr name zones.${zone}) zoneNames;

  # For real flake hosts, resolve the host's primary zone by comparing the
  # host's primary address (`flake.networking.records.<host>`) against the raw
  # zone maps. This mirrors the repo rule that `networking.domain` selects the
  # primary SSH/DNS identity for each host.
  primaryZoneFor = host: let
    primaryIp = flake.networking.records.${host} or null;
    matches = filter (zone: primaryIp != null && (zones.${zone}.${host} or null) == primaryIp) zoneNames;
  in
    if matches == []
    then null
    else head matches;

  mkBlock = {
    hostName,
    user ? username,
    port ? null,
  }:
    {
      hostname = hostName;
      inherit user;
    }
    // lib.optionalAttrs (port != null) {inherit port;};

  # Every zone record gets a fully qualified alias like `logos.home`. These are
  # always safe because they preserve the zone context explicitly.
  longBlocks = listToAttrs (
    map (record:
      nameValuePair "${record.name}.${record.zone}" (mkBlock {
        hostName = "${record.name}.${record.zone}";
      }))
    zoneRecords
  );

  # Real flake hosts also get a short alias using their primary zone, e.g.
  # `cog -> cog.tail` and `eve -> eve.work`. Even if a host exists in multiple
  # zones, the short alias should track the host's primary flake identity.
  shortHostBlocks = listToAttrs (
    map (host:
      nameValuePair host (mkBlock {
        hostName = "${host}.${primaryZoneFor host}";
      }))
    (filter (host: primaryZoneFor host != null) flakeHosts)
  );

  # Non-host zone records get short aliases only when the name is unique across
  # all zones. Example: `logos -> logos.home` is safe, but `cog` is not.
  shortZoneBlocks = let
    names = lib.unique (map (record: record.name) zoneRecords);
  in
    listToAttrs (
      map (name: let
        hostZones = zoneNamesFor name;
      in
        nameValuePair name (mkBlock {
          hostName = "${name}.${head hostZones}";
        }))
      (filter (name: !builtins.elem name flakeHosts && builtins.length (zoneNamesFor name) == 1) names)
    );

  # Repo-wide exceptions that cannot be inferred from zones alone.
  # Example: `sim` is reachable over an SSH port forward on localhost, not by
  # its tailnet address.
  sharedOverrides = {
    sim = mkBlock {
      hostName = "localhost";
      port = 2222;
    };
  };
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Optional local overlay outside the public flake for work/client/public
    # hosts you do not want to publish. OpenSSH tolerates missing include
    # targets here, so a machine without `~/.ssh/config.local` still works.
    includes = ["~/.ssh/config.local"];

    # Home Manager renders `Host *` at the bottom when it is expressed as the
    # default match block, which is where SSH expects broad fallback settings.
    # Put shared defaults here instead of `extraConfig` so ordering stays
    # stable and explicit.
    matchBlocks =
      longBlocks
      // shortHostBlocks
      // shortZoneBlocks
      // sharedOverrides
      // {
        "*" = {
          identityFile = ["~/.ssh/id_ed25519" "~/.ssh/id_rsa"];
          identitiesOnly = true;
          addKeysToAgent = "8h";
          forwardAgent = false;
          controlMaster = "auto";
          controlPath = "~/.ssh/control-%C";
          controlPersist = "10m";
          extraOptions.StrictHostKeyChecking = "accept-new";
          extraOptions.LogLevel = "ERROR";
        };
      };
  };

  # Start a user ssh-agent everywhere this shared module is imported. Keep the
  # default identity lifetime aligned with the `Host *` AddKeysToAgent value.
  services.ssh-agent = {
    enable = true;
    defaultMaximumIdentityLifetime = 28800; # 8h
  };
}
