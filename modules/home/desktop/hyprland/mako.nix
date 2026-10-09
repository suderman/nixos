{
  config,
  lib,
  pkgs,
  ...
}: {
  stylix.targets.mako.enable = lib.mkIf config.programs.desktop-theme.enable false;

  home.packages = [
    (pkgs.self.mkScript {
      name = "notification-mode";
      path = [pkgs.mako pkgs.procps pkgs.jq];
      text = ''
        case "''${1:-toggle}" in
          toggle)
            makoctl mode -t do-not-disturb
            # Nix wraps the executable; its process name is .waybar-wrapped.
            pkill -RTMIN+10 -u "$UID" -x 'waybar|\.waybar-wrapped' || true
            ;;
          status)
            modes=$(makoctl mode)
            if grep -qx do-not-disturb <<< "$modes"; then
              jq -cn '{text: "󰂛", class: "silenced", tooltip: "Notifications silenced. Click to resume."}'
            else
              jq -cn '{text: "󰂚", class: "normal", tooltip: "Notifications on. Click to silence."}'
            fi
            ;;
          *) printf "Usage: notification-mode [toggle|status]\n" >&2; exit 64 ;;
        esac
      '';
    })
  ];

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 6000;
      include = lib.mkIf config.programs.desktop-theme.enable "${config.xdg.stateHome}/desktop-theme/current/mako.conf";
      progress-color = lib.mkIf (!config.programs.desktop-theme.enable) (lib.mkDefault "over #${config.lib.stylix.colors.base02}");
      border-radius = 7;
      border-color = lib.mkIf (!config.programs.desktop-theme.enable) (lib.mkDefault "#${config.lib.stylix.colors.base0D}");
      border-size = 2;
      padding = "15";
      width = 600;
      height = 300;
      text-color = lib.mkIf (!config.programs.desktop-theme.enable) (lib.mkDefault "#${config.lib.stylix.colors.base05}");
      background-color = lib.mkIf (!config.programs.desktop-theme.enable) (lib.mkDefault "#${config.lib.stylix.colors.base00}");
      font = lib.mkDefault "${config.stylix.fonts.sansSerif.name} ${toString config.stylix.fonts.sizes.popups}";
      "mode=do-not-disturb".invisible = true;
      anchor = "bottom-left";
      # "[urgency=normal]" = {
      #   border-color = "#ef9f76";
      # };
      # "[urgency=low]" = {
      #   border-color = "#ef9f76";
      # };
      # "[urgency=high]" = {
      #   border-color = "#ef9f76";
      #   default-timeout = "0";
      # };
    };

    # extraConfig = ''
    #   [urgency=normal]
    #   border-color=#ef9f76
    #
    #   [urgency=low]
    #   border-color=#ef9f76
    #
    #   [urgency=high]
    #   border-color=#ef9f76
    #   default-timeout=0
    # '';
    # [mode=do-not-disturb]
    # invisible=1
  };

  wayland.windowManager.hyprland.lua.features.mako =
    # lua
    ''
      util.exec("ESCAPE", "makoctl dismiss", { non_consuming = true })
      util.exec("SUPER + ALT + U", "makoctl restore")
      util.exec("SUPER + ALT + SHIFT + U", "notification-mode toggle", { description = "Silence/resume notifications" })

      hl.layer_rule({
        name = "notifications-slide",
        match = { namespace = "^notifications$" },
        animation = "slide",
      })
    '';
}
