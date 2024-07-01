{ config, lib, ... }: {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    programs.firefox = {
      enable = true;
      profiles = {};
    };

    # tag Firefox and Picture-in-Picture windows
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "tag +web, class:[Ff]irefox"
        "tag +pip, title:^(Picture-in-Picture)$"
      ];
    };

    # keyboard shortcuts
    services.keyd.applications = {
      firefox = {
        "alt.f" = "C-f"; # find in page
        "alt.l" = "C-l"; # location bar
        "super.o" = "C-l"; # location bar
        "super.t" = "C-t"; # new tab
        "super.w" = "C-w"; # close tab
        "super.[" = "C-pageup"; # prev tab
        "super.]" = "C-pagedown"; # next tab
        "super.n" = "C-n"; # new window
        "super.r" = "C-r"; # reload
      };
    };

  };

}
