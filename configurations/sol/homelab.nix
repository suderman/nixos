{ config, lib, pkgs, ... }: { 

  # Experiments
  # modules.whoogle = { enable = true; name = "g.suderman.net"; };
  # services.gitea = { enable = true; name = "git"; };
  # modules.wallabag.enable = false;
  # modules.nextcloud.enable = false;
  modules.tandoor-recipes = {
    enable = false;
    package = pkgs.unstable.tandoor-recipes;
    public = "tandoor.suderman.net";
  };

  services.traefik = {
    routers."wiki.zz" = "https://wiki.sol";
    extraInternalHostNames = [ "wiki.zz" ];
  };

}
