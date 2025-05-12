{ inputs, lib, ... }: {

  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  # Prepare nix-index module with weekly updated database and comma integration
  programs = let inherit (lib) mkDefault; in {
    nix-index-database.comma.enable = mkDefault true; 
    nix-index.enableBashIntegration = mkDefault false; 
    nix-index.enableZshIntegration = mkDefault false; 
    nix-index.enableFishIntegration = mkDefault false;
    command-not-found.enable = mkDefault false;
  };

}
