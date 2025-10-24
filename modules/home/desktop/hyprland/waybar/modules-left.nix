{pkgs, ...}: {
  programs.waybar.settings.bar = {
    modules-left = [
      "custom/launcher"
      "hyprland/workspaces"
    ];

    "custom/launcher" = {
      on-click = "launcher";
      format = "";
    };

    "hyprland/workspaces" = {
      on-click = "activate";
      all-outputs = false;
      disable-scroll = true;
      active-only = false;
      show-special = false;
      format = "{icon}";
      format-icons = {
        default = "";
        "1" = "1";
        "2" = "2";
        "3" = "3";
        "4" = "4";
        "5" = "5";
        "6" = "6";
        "7" = "7";
        "8" = "8";
        "9" = "9";
      };
    };
  };
}
