{ inputs, config, lib, pkgs, username, ... }: 

with builtins;

let

in {

  # ---------------------------------------------------------------------------
  # COMMON CONFIGURATION FOR ALL HOMES
  # ---------------------------------------------------------------------------
  imports = [ ./. inputs.homeage.homeManagerModules.homeage ];


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

  ];

  programs = {
    neovim.enable = true;
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


  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------

  home.username = username;
  home.homeDirectory = "/${if (pkgs.stdenv.isLinux) then "home" else "Users"}/${username}";


  # ---------------------------------------------------------------------------
  # Home Settings
  # ---------------------------------------------------------------------------

  # # https://github.com/nix-community/home-manager/issues/1439#issuecomment-1106208294
  # home.activation = {
  #   linkDesktopApplications = {
  #     after = [ "writeBoundary" "createXdgUserDirectories" ];
  #     before = [ ];
  #     data = ''
  #       rm -rf ${config.xdg.dataHome}/"applications/home-manager"
  #       mkdir -p ${config.xdg.dataHome}/"applications/home-manager"
  #       cp -Lr ${config.home.homeDirectory}/.nix-profile/share/applications/* ${config.xdg.dataHome}/"applications/home-manager/"
  #     '';
  #   };
  # };

  # Enable home-manager and git
  programs.home-manager.enable = true;
  # programs.git.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Configure homeage (agenix for home-manager)
  homeage.identityPaths = [ "~/.ssh/id_rsa" ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.05";

}
