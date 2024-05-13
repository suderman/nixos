# services.keyd.enable = true;
{ config, lib, pkgs, ... }: 

with pkgs; 

let 
  cfg = config.modules.keyd;

in {
  options = {
    modules.keyd.enable = lib.options.mkEnableOption "keyd"; 
  };

  config = lib.mkIf cfg.enable {

    # home.packages = [ pkgs.keyd ];

    xdg.configFile = {
      "keyd/app.conf".text = ''

        [alacritty]

        alt.] = macro(C-g n)
        alt.[ = macro(C-g p)

        [chromium]

        alt.[ = C-S-tab
        alt.] = macro(C-tab)

        [org-gnome-nautilus]

        alt.enter = f2
        alt.r = f2
        alt.i = C-i

        #[org-wezfurlong-wezterm]

        #leftalt = layer(meta_cmd)

        [firefox]

        # control.a = home
        # control.e = end
        # control.f = right
        # control.b = left
        # control.w = C-right
        alt.f = C-f

        [geary]

        [telegramdesktop]

        [1password]

        [fluffychat]

        [gimp-2-9]

        [obsidian]

        [slack]
      '';
    };

  };

}
