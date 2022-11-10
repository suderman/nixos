# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, host, lib, config, pkgs, ... }: 

let 
  inherit (host) hostname username userdir system;
in {

  imports = [
    ./cli
    ./gui
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.05";

  xdg.configFile = let flags = ''
    --enable-features=UseOzonePlatform 
    --ozone-platform=wayland
    '';
  in {
    "chromium-flags.conf".text = flags;
    "electron-flags.conf".text = flags;
    "electron-flags16.conf".text = flags;
    "electron-flags17.conf".text = flags;
    "electron-flags18.conf".text = flags;
    "electron-flags19.conf".text = flags;
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
  };


  # Enable home-manager and git
  programs.home-manager.enable = true;
  # programs.git.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.username = username;
  home.homeDirectory = userdir; 

  # https://github.com/nix-community/home-manager/issues/1439#issuecomment-1106208294
  home.activation = {
    linkDesktopApplications = {
      after = [ "writeBoundary" "createXdgUserDirectories" ];
      before = [ ];
      data = ''
        rm -rf ${config.xdg.dataHome}/"applications/home-manager"
        mkdir -p ${config.xdg.dataHome}/"applications/home-manager"
        cp -Lr ${config.home.homeDirectory}/.nix-profile/share/applications/* ${config.xdg.dataHome}/"applications/home-manager/"
      '';
    };
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [ 
    # nerdfonts
    # joypixels
    nur.repos.mic92.hello-nur
    (me.enableWayland element-desktop "element-desktop")
    (me.enableWayland signal-desktop "signal-desktop")
    (me.enableWayland slack "slack")
    tdesktop
    newsflash
    unstable.sl
    yo
    unstable.nnn 
    unstable.exa
    owncloud-client
    _1password
    (me.enableWayland _1password-gui "1password")
    owofetch
    firefox-wayland
    (me.enableWayland plexamp "plexamp")
    xorg.xeyes
  ];

  programs = {
    neovim.enable = true;
    chromium = {
      enable = true;
      commandLineArgs = [ "--enable-features=UseOzonePlatform" "-ozone-platform=wayland" "--gtk-version=4" ];
    };
  };

}
