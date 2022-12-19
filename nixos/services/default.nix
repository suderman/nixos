{ ... }: 
{
  imports = [
    ./keyd.nix
    ./ocis.nix
    ./openssh.nix
    ./pipewire.nix
    ./tailscale.nix
    ./tandoor-recipes.nix
    ./traefik.nix
    ./whoami.nix
    ./whoogle.nix
  ];
}
