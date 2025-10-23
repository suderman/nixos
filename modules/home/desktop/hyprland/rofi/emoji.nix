{pkgs, ...}: {
  programs.rofi = {
    plugins = [pkgs.unstable.rofi-emoji];
    extraConfig.modes = ["emoji"];
    rasiConfig = [''emoji { display-name: ""; }''];
  };
}
