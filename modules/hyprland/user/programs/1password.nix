{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    home.packages = with pkgs; [ 
      _1password-cli
      _1password-gui 
    ];

    # Float and resize
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        # Main window
        "tag +pwd, class:(1Password), title:^(1Password)$"
        # "float, tag:pwd"
        "size 1024 768, tag:pwd"

        # Dialog window
        "tag +pwd_dialog, class:(1Password), title:^(.*)Password — 1Password$"
        "float, tag:pwd_dialog"
        "size 1280 240, tag:pwd_dialog"
        "center, tag:pwd_dialog"
        "pin, tag:pwd_dialog"
      ];
    };

    # keyboard shortcuts
    services.keyd.windows = {
      "1password" = {
        "esc" = "C-w";
      };
    };

  };

}
