{ ... }: 
{
  imports = [
    ./docker.nix
    ./keyd.nix
    ./mysql.nix
    ./ocis.nix
    ./openssh.nix
    ./postgresql.nix
    ./sabnzbd.nix
    ./tailscale.nix
    ./tandoor-recipes.nix
    ./traefik.nix
    ./whoami.nix
    ./whoogle.nix
  ];
}
