{ config, lib, pkgs, ... }: {

  # Docker
  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";
  };

}
