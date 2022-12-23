{ inputs, config, lib, pkgs, username, nixos, ... }: 

with builtins;

let
  inherit (pkgs) stdenv; 

in {

  imports = [ ../. ];

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------

  home.username = username;
  home.homeDirectory = "/${if (stdenv.isLinux) then "home" else "Users"}/${username}";

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

  # Enable home-manager, git & zsh
  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.zsh.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.05";

}
