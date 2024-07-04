{ config, lib, pkgs, ... }: { 

  # Experiments
  # services.whoogle = { enable = true; name = "g.suderman.net"; };
  # services.gitea = { enable = true; name = "git"; };
  # modules.nextcloud.enable = false;

  services.tandoor-recipes = {
    enable = false;
    package = pkgs.unstable.tandoor-recipes;
    public = "tandoor.suderman.net";
  };

  services.traefik = {
    routers."wiki.zz" = "https://wiki.sol";
    extraInternalHostNames = [ "wiki.zz" ];
  };

}
