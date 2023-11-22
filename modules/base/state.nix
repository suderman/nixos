# Add directories or files to persist
# modules.base.dirs = [ "/var/lib/systemd" ];
# modules.base.files = [ "/etc/machine-id" ];
{ config, lib, inputs, ... }: 

let 

  cfg = config.modules.base;
  inherit (lib) mkBefore mkIf;

in {
  
  # Import impermanence module
  imports = [ inputs.impermanence.nixosModule ];

  # Script to wipe the root subvolume at boot
  boot.initrd.postDeviceCommands = mkBefore (builtins.readFile ./initrd.sh);

  # Configuration impermanence module
  environment.persistence = {

    # State stored on subvolume
    "${cfg.stateDir}" = {
      hideMounts = true;

      # System files
      files = cfg.files;

      # System directories
      directories = [
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/var/lib"  
        "/var/log"  
        "/home"  
      ] ++ cfg.dirs;

    };
  };

  # Allows users to allow others on their binds
  programs.fuse.userAllowOther = true;

  # Maintain machine identification
  environment.etc."machine-id".source = "${cfg.stateDir}/etc/machine-id";

  # Maintain ssh host keys
  services.openssh = mkIf config.services.openssh.enable {
    hostKeys = [{
      path = "${cfg.stateDir}/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    } {
      path = "${cfg.stateDir}/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }];
  };

}
