# osConfig.stylix.enable = true;
{
  config,
  osConfig,
  lib,
  ...
}: let
  cfg = config.stylix;
  oscfg = osConfig.stylix;
  inherit (lib) mkIf mkDefault mkForce;
in {
  config.stylix = mkIf oscfg.enable {
    # Enable with nixos module
    enable = mkDefault true;
    autoEnable = mkDefault oscfg.enable;

    targets = {
      firefox.profileNames = ["default"];
      hyprpaper.enable = mkForce false; # don't set my wallpaper
      # alacritty.enable = false;
      # avizo.enable = false;
      # bat.enable = false;
      # bemenu.enable = false;
      # bspwm.enable = false;
      # btop.enable = false;
      # dunst.enable = false;
      # emacs.enable = false;
      # feh.enable = false;
      # firefox.enable = false;
      # fish.enable = false;
      # foot.enable = false;
      # forge.enable = false;
      # fuzzel.enable = false;
      # fzf.enable = false;
      # gedit.enable = false;
      # gitui.enable = false;
      # gnome.enable = false;
      # gtk.enable = false;
      # helix.enable = false;
      # hyprland.enable = false;
      # hyprlock.enable = false;
      # hyprpaper.enable = false;
      # i3.enable = false;
      # k9s.enable = false;
      # kde.enable = false;
      # kitty.enable = false;
      # kubecolor.enable = false;
      # lazygit.enable = false;
      # mako.enable = false;
      # mangohud.enable = false;
      # ncspot.enable = false;
      # neovim.enable = false;
      # nixvim.enable = false;
      # nushell.enable = false;
      # qutebrowser.enable = false;
      # river.enable = false;
      # rofi.enable = false;
      # spicetify.enable = false;
      # sway.enable = false;
      # swaylock.enable = false;
      # swaync.enable = false;
      # sxiv.enable = false;
      # tmux.enable = false;
      # tofi.enable = false;
      # vesktop.enable = false;
      # vim.enable = false;
      # vscode.enable = false;
      # waybar.enable = false;
      # wezterm.enable = false;
      # wob.enable = false;
      # wofi.enable = false;
      # wpaperd.enable = false;
      # xfce.enable = false;
      # xresources.enable = false;
      # yazi.enable = false;
      # zathura.enable = false;
      # zellij.enable = false;
    };
  };
}
