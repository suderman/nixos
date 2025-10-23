{pkgs, ...}: {
  programs.rofi = {
    plugins = [pkgs.unstable.rofi-emoji];
    mode.slot2 = "emoji";
    rasiConfig = [''emoji { display-name: ""; }''];
  };
}
