{
  config,
  lib,
  flake,
  ...
}: let
  cfg = config.virtualisation.docker;
in {
  # Enable Docker and set to backend (over podman default)
  virtualisation = {
    docker = {
      enable = lib.mkDefault true;
      storageDriver = "overlay2";
      liveRestore = false; # enabling this is incompatiable with docker swarm
    };
    oci-containers.backend = "docker";
  };

  # Persist without snapshots
  persist = lib.mkIf cfg.enable {
    scratch.directories = ["/var/lib/docker"];
  };

  systemd.services.docker = lib.mkIf cfg.enable {
    after = ["var-lib-docker.mount"];
    requires = ["var-lib-docker.mount"];
  };

  # Add config's users to the docker group
  users.users = lib.mkIf cfg.enable (flake.lib.extraGroups config ["docker"]);
}
