# programs.zwift.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.programs.zwift;
  inherit (lib) mkIf options;
  inherit (config.lib.keyd) mkClass;

  # Window class name
  class = "zwiftapp.exe";
in {
  options.programs.zwift = {
    enable = options.mkEnableOption "zwift";
  };

  config = mkIf cfg.enable {
    # Add to path
    home.packages = [perSystem.self.zwift];

    # Persist credentials
    persist.storage.directories = [".local/share/zwift"];

    # Window rules
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        "tile,class:(${class})" # don't float
      ];
    };

    # Keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      # "h" = "left";
      # "j" = "down"; # u-turn
      # "k" = "up"; # show menu
      # "l" = "right";
      # "f" = "f1"; # elbow flick
      # "w" = "f2"; # wave hand
      # "r" = "f3"; # ride on
      # "g" = "f4"; # hammer time
      # "n" = "f5"; # nice
      # "b" = "f6"; # bring it
      # "q" = "f7"; # i'm toast
      # "o" = "f8"; # bike bell
      # "p" = "f10"; # screen capture
      # "shift.q" = "q";
      # "shift.w" = "w";
      # "shift.e" = "e"; # workout selection screen
      # "shift.r" = "r";
      # "shift.t" = "t"; # user customization screen
      # "shift.y" = "y";
      # "shift.u" = "u";
      # "shift.i" = "i";
      # "shift.o" = "o";
      # "shift.p" = "p"; # promo code
      # "shift.a" = "a"; # device pairing screen
      # "shift.s" = "s";
      # "shift.d" = "d";
      # "shift.f" = "f";
      # "shift.g" = "g"; # toggle watt/hr graph
      # "shift.h" = "h"; # hide hud
      # "shift.j" = "j";
      # "shift.k" = "k";
      # "shift.l" = "l";
      # "shift.z" = "z";
      # "shift.x" = "x";
      # "shift.c" = "c";
      # "shift.v" = "v";
      # "shift.b" = "b";
      # "shift.n" = "n";
      # "shift.m" = "m"; # message window
      "leftbracket" = "pagedown"; # adjust intensity down
      "rightbracket" = "pageup"; # adjust intensity up
      # 0-9 = camera angles
      # tab = skip workout block
    };
  };
}
