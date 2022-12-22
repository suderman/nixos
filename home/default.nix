{ ... }: 
{
  imports = [
    ../secrets
    ./cli
    ./gui
    ./persist.nix
  ];
}
