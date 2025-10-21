# Programs and packages required by my Hyprland
{pkgs, ...}: {
  # Check modules directory for extra configuration
  programs = {
    bluetuith.enable = true; # bluetooth tui
    cava.enable = true; # audio visualizer
  };

  # Add these to my path
  home.packages = with pkgs; [
    brightnessctl

    unstable.wiremix # sound control
    font-awesome # icon font
    jetbrains-mono # mono font

    nemo-with-extensions # file manager gui
    junction # browser chooser

    # quickemu # virtual machines
  ];
}
