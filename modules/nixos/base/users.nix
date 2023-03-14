# base.enable = true;
{ config, lib, pkgs, user, ... }: with lib; with builtins; 

let
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # public keys from the secrets dir
  keys = config.secrets.keys;

  # agenix secrets combined with age files paths
  age = config.age // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };

in {

  config = mkIf config.base.enable {

    # agenix
    age.secrets = mkIf age.enable {
      password.file = age.files.password;
    };

    # ---------------------------------------------------------------------------
    # User Configuration
    # ---------------------------------------------------------------------------
    users.mutableUsers = false;

    # # personal user
    # users.users."${user}" = {
    #   isNormalUser = true;
    #   shell = pkgs.zsh;
    #   home = "/home/${user}";
    #   description = user;
    #   passwordFile = mkIf (age.enable) age.secrets.password.path;
    #   password = mkIf (!age.enable) "${user}";
    #   extraGroups = [ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" ]; 
    #   openssh.authorizedKeys.keys = [ keys.users."${user}" ];
    # };
    #
    # # test user
    # users.users."test" = {
    #   isNormalUser = true;
    #   shell = pkgs.zsh;
    #   home = "/home/test";
    #   description = "test";
    #   passwordFile = mkIf (age.enable) age.secrets.password.path;
    #   password = mkIf (!age.enable) "test";
    #   extraGroups = [ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" ]; 
    #   openssh.authorizedKeys.keys = [ keys.users."${user}" ];
    # };

    # users.users = (if user == false then {} else {
      users.users = mkMerge [ 
        (if (user == false) then {} else {
          "${user}" = {
            isNormalUser = true;
            shell = pkgs.zsh;
            home = "/home/${user}";
            description = user;
            passwordFile = mkIf (age.enable) age.secrets.password.path;
            password = mkIf (!age.enable) "${user}";
            extraGroups = [ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" ]; 
            openssh.authorizedKeys.keys = [ keys.users."${user}" ];
          };
        }) ({
          "root" = {
            shell = pkgs.zsh;
            passwordFile = mkIf (age.enable) age.secrets.password.path;
            password = mkIf (!age.enable) "root";
            openssh.authorizedKeys.keys = mkIf (user != false) [ keys.users."${user}" ];
          };
        })
      ];

    # } // {

      # # root user

    # };

   #  # root user
   # users.users."root" = {
   #    shell = pkgs.zsh;
   #    passwordFile = mkIf (age.enable) age.secrets.password.path;
   #    password = mkIf (!age.enable) "root";
   #    openssh.authorizedKeys.keys = mkIf (user != false) [ keys.users."${user}" ];
   #  };

    # # root user
    # users.users.root = {
    #   shell = pkgs.zsh;
    #   passwordFile = mkIf (age.enable) age.secrets.password.path;
    #   password = mkIf (!age.enable) "root";
    #   openssh.authorizedKeys.keys = [ keys.users."${user}" ];
    # };

    # Allow root to work with git on the /etc/nixos directory
    system.activationScripts.root.text = ''
      printf "[safe]\ndirectory = /etc/nixos" > /root/.gitconfig
    '';

  };

}
