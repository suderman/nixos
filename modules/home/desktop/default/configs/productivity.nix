{
  lib,
  pkgs,
  ...
}: {
  programs = {
    onepassword.enable = lib.mkDefault true;
    gmail.enable = lib.mkDefault true;
    google-calendar.enable = lib.mkDefault true;
    google-meet.enable = lib.mkDefault true;
    google-analytics.enable = lib.mkDefault true;
    harvest.enable = lib.mkDefault true;
    asana.enable = lib.mkDefault true;
    obsidian.enable = lib.mkDefault true;
  };

  home.packages = with pkgs; [
    lapce # text editor
    libreoffice # office suite (writing, spreadsheets, etc)
    neovide # text editor
    qalculate-gtk # calculator
  ];
}
