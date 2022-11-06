{ config, inputs, lib, pkgs, host, ... }:
let 
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  inherit (host) hostname username userdir system;
in {

  users = {
    mutableUsers = false;
    users."${username}" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      home = userdir;
      description = username;
      extraGroups = [ 
        "wheel" 
      ] ++ ifTheyExist [
        "networkmanager" 
        "docker" 
        "input" 
        "keyd" 
      ]; 
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqkkVHSFBPNT9ajrgq1lFKNhkf1QJMZgobkL8fsKlx3mle7Ug5GvW/HLymAsfP04zA1CPet4awcufEEolwY7tWfDIdCOi+8xgaJh5Te3AM9Twegc3a2CRL21Mv438LCPU03qhzHh4JPBWbatq5QxTti67joC91XiBjY/vl8aRtyUz2n/tFoS3yhfMb2qP+VU75dgWQw+WDtHbG4bT018JcL+G4wexKBM3vs51t7qdHHkcbjJh/XJ+/+WGg4SkpmzREEtL2VVh7Mn/e0jupZcU4wtsoi7652bYh1kFpi0YvlTWpdwLmhUXx1RpIYsuP/TNePoN+GBcKN+9dmJuJLJFseD8xhuYzOVpFLb/GdXWEAUlMtCdHwg1QjEUcBPTaX0CeLY/kmna1MU4SBGQ6msTDwSNUpEkKEaiv6Fx66XstAzf1g5NEauLw/YGgwDsPGgPfCraS03aJCqieHxBHe5uaD1vBA4zFvV3CBv3uvlKBUsgVbR2A1k4Bvpyw6VlasvpZhh0DoDVWNL30SvTtyVCS1sIey0GwGNYBVDBu5P5LHsCgOESKG32uHkXVEeYTdln35dJyoxP+/zMebJwNTZjGjU19ORthViwibfQMV2J931ZjkLWgVqxnn9t0hltC2845eOJ0BytX5wFxqf4IU5Ix/yuMeUwIlLocz6X6blNbsQ== me@blink" ];
    };

  };

}
