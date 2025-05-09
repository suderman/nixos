{ lib, ... }: {

  # Enable Docker and set to backend (over podman default)
  virtualisation = {
    docker.enable = lib.mkDefault true;
    docker.storageDriver = "overlay2";
    docker.liveRestore = false; # enabling this is incompatiable with docker swarm
    oci-containers.backend = "docker";
  };

  # Persist data after reboots
  persist.directories = [ "/var/lib/docker" ];

}
