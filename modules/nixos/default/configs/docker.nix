{
  config,
  lib,
  flake,
  ...
}: let
  cfg = config.virtualisation.docker;
  inherit (lib) mkDefault mkIf;
in {
  # Enable Docker and set to backend (over podman default)
  virtualisation = {
    docker = {
      enable = mkDefault true;
      storageDriver = "overlay2";
      liveRestore = false; # enabling this is incompatiable with docker swarm
    };
    oci-containers.backend = "docker";
  };

  persist = mkIf cfg.enable {
    # Persist these directories between reboots
    scratch.directories = [
      "/var/lib/docker/containers"
      "/var/lib/docker/image"
      "/var/lib/docker/overlay2"
    ];
    # Persist these as well, but also make snapshots
    storage.directories = [
      "/var/lib/docker/volumes"
      "/var/lib/docker/swarm"
    ];
  };

  # Add config's users to the docker group
  users.users = mkIf cfg.enable (flake.lib.extraGroups config ["docker"]);
}
