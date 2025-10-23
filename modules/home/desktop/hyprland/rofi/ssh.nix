{...}: {
  programs.rofi = {
    extraConfig.modes = ["ssh"];
    rasiConfig = [''ssh { display-name: ""; }''];
  };
}
