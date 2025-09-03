{
  config,
  lib,
  flake,
  ...
}: let
  cfg = config.virtualisation.docker;
  inherit (lib) mkIf;
in {
  # Enable Docker and set to backend (over podman default)
  virtualisation = {
    docker.storageDriver = "overlay2";
    docker.liveRestore = false; # enabling this is incompatiable with docker swarm
    oci-containers.backend = "docker";
  };

  # Persist data after reboots
  persist = mkIf cfg.enable {
    scratch.files = ["/var/lib/docker/engine-id"];
    scratch.directories = [
      "/var/lib/docker/containers"
      "/var/lib/docker/image"
      "/var/lib/docker/overlay2"
    ];
    storage.directories = [
      "/var/lib/docker/volumes"
      "/var/lib/docker/swarm"
    ];
  };

  # Add config's users to the docker group
  users.users = mkIf cfg.enable (flake.lib.extraGroups config ["docker"]);
}
