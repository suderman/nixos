{ ... }: 
{
  imports = [
    ./docker.nix
    ./keyd.nix
    ./ocis.nix
    ./openssh.nix
    ./pipewire.nix
    ./sabnzbd.nix
    ./tailscale.nix
    ./tandoor-recipes.nix
    ./traefik.nix
    ./whoami.nix
    ./whoogle.nix
  ];
}
