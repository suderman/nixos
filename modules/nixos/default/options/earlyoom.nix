{...}: {
  services.earlyoom = {
    freeSwapThreshold = 10; # % default
    freeMemThreshold = 10; # % default
    extraArgs = [
      "-g"
      # "--avoid '^(Hyprland|kitty)$'"
      # "--prefer '^(chromium|firefox|electron|libreoffice|gimp)$'"
    ];
  };
}
