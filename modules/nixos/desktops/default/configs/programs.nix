{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    desktop-file-utils # desktop-file-edit desktop-file-install desktop-file-validate update-desktop-database
    hicolor-icon-theme # fallback icon theme
    shared-mime-info # update-mime-database
    wl-clipboard # wl-copy wl-paste
    xdg-user-dirs # xdg-user-dir xdg-user-dirs-update
    xdg-utils # xdg-desktop-icon xdg-desktop-menu xdg-email xdg-icon-resource xdg-mime xdg-open xdg-screensaver xdg-settings xdg-terminal
  ];

  # AirDrop alternative
  programs.localsend.enable = true;
}
