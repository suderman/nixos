{ config, lib, pkgs, ... }: {

  imports = [ ../. ];

  # ---------------------------------------------------------------------------
  # Home Enviroment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    nerdfonts
    joypixels
    nur.repos.mic92.hello-nur
    tdesktop
    newsflash
    unstable.sl
    yo
    unstable.nnn 
    _1password
    owofetch
    dolphin
    _1password-gui
    owncloud-client
    element-desktop
    signal-desktop
    slack
    firefox-wayland
    xorg.xeyes
    plexamp

    webex

  ];

  state.files = [
    # ".nix-channels"
    ".zsh_history"
    ".bash_history"
    "myfile.txt"
    ".screenrc"
  ];

  state.dirs = [ 
    # "Downloads" 
    # "Desktop"
    # ".local/share/Trash"
    # ".local/share/keyrings"
    "test-four" 
    "test-five" 
  ];

  # home.persistence."/nix/home".files = [
  #   "awesome.txt"
  # ];

  programs = {
    # neovim.enable = true;
    chromium = {
      enable = true;
      commandLineArgs = [ "--enable-features=UseOzonePlatform" "-ozone-platform=wayland" "--gtk-version=4" ];
    };
  };

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


}
