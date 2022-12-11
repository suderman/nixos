{ config, inputs, lib, pkgs, username, ... }: with builtins; 
let ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;
in {

  users = {
    users."${username}" = with pkgs; {
      isNormalUser = true;
      shell = zsh;
      home = "/home/${username}";
      description = username;
      extraGroups = [ 
        "wheel" 
      ] ++ ifTheyExist [
        "networkmanager" 
        "docker" 
        "input" 
        "keyd" 
      ]; 
      openssh.authorizedKeys.keys = [ config.keys."${username}" ];
    };
    mutableUsers = true;
  };

  environment.systemPackages = with pkgs; [
    home-manager
  ];

  # environment.etc."scratch/keys.txt".text = ''
  #   # me
  #   ${config.keys.me}
  #   # 
  #   # cog
  #   ${config.keys.cog}
  #   # 
  #   # lux
  #   ${config.keys.lux}
  # '';
  #
  # environment.etc."scratch/domain.txt".source = config.age.secrets.domain.path;

}
