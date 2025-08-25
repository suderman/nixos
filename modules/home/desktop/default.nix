{
  pkgs,
  flake,
  ...
}: {
  # Import all *.nix files in this directory
  imports = flake.lib.ls ./.;

  home.packages = with pkgs; [
    lapce # text editor
    libreoffice # office suite (writing, spreadsheets, etc)
    newsflash # rss reader
  ];

  programs.chromium.enable = true;
  programs.foot.enable = false;
  programs.wezterm.enable = false;

  services.flatpak.enable = true;

  persist.storage.directories = [".local/state/wireplumber"];
}
