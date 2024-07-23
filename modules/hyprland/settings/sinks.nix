{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) concatStringsSep hm mkIf mkOption mkShellScript types;

  # Script triggered by hyprland start and also home-manager activation
  sinks = let 
    extraSinks = concatStringsSep "\n" cfg.extraSinks;
    hiddenSinks = concatStringsSep "\n" cfg.hiddenSinks;
  in ''
    ''${DRY_RUN_CMD-} mkdir -p $XDG_RUNTIME_DIR/sinks
    ''${DRY_RUN_CMD-} echo "${extraSinks}" > $XDG_RUNTIME_DIR/sinks/extra
    ''${DRY_RUN_CMD-} echo "${hiddenSinks}" > $XDG_RUNTIME_DIR/sinks/hidden
  '';

in {

  options.wayland.windowManager.hyprland = {
    extraSinks = mkOption { 
      type = with types; listOf str; default = [];
    };
    hiddenSinks = mkOption { 
      type = with types; listOf str; default = [];
    };
  };

  config = mkIf cfg.enable {

    # Init sinks when hyprland loads
    wayland.windowManager.hyprland.settings.exec-once = [ 
      "${mkShellScript { inputs = [ pkgs.coreutils ]; text = sinks; }}"
    ];

    # Also init upon activation so I don't need to login again
    home.activation.sinks = hm.dag.entryAfter [ "writeBoundary" ] sinks;

  };

}
