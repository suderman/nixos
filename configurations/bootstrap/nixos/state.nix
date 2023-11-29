{ config, lib, inputs, ... }: 

let 

  # Persist state in this subvolume
  stateDir = "/nix/state";

  extraDirs = []; # [ "/var/lib/systemd" ];
  extraFiles = []; # [ "/etc/machine-id" ];

  inherit (lib) mkBefore mkIf;

in {
  
  # Import impermanence module
  imports = [ inputs.impermanence.nixosModule ];

  # Script to wipe the root subvolume at boot
  boot.initrd.postDeviceCommands = mkBefore (builtins.readFile ./initrd.sh);

  # Configuration impermanence module
  environment.persistence = {

    # State stored on subvolume
    "${stateDir}" = {
      hideMounts = true;

      # System files
      files = extraFiles;

      # System directories
      directories = [
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/var/lib"  
        "/var/log"  
        "/home"  
      ] ++ extraDirs;

    };
  };

  # Allows users to allow others on their binds
  programs.fuse.userAllowOther = true;

  # Maintain machine identification
  environment.etc."machine-id".source = "${stateDir}/etc/machine-id";

  # Maintain ssh host keys
  services.openssh = mkIf config.services.openssh.enable {
    hostKeys = [{
      path = "${stateDir}/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    } {
      path = "${stateDir}/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }];
  };

}
