# https://www.linode.com/docs/guides/install-nixos-on-linode/
{ config, lib, pkgs, ... }: 

let 
  cfg = config.linode;

in {
  options = {
    linode.enable = lib.options.mkEnableOption "linode"; 
  };

  # linode.enable = true;
  config = lib.mkIf cfg.enable {

    # Enable LISH for Linode
    boot.kernelParams = [ "console=ttyS0;19200n8" ];
    boot.loader.grub.extraConfig = ''
      serial --speed=19200 --unit=0 --word=8 --parity=non --stop=1;
      terminal_input serial;
      terminal_output serial
    '';

    # Configure GRUB for Linode
    boot.loader.grub.forceInstall = true;
    boot.loader.grub.device = "nodev";
    boot.loader.timeout = 10;

    # Disable predictable interface names for Linode
    networking.usePredictableInterfaceNames = false;
    networking.useDHCP = false; # Disable DHCP globally as we will not need it.
    networking.interfaces.eth0.useDHCP = true;

    # # Enable Longview Agent for Linode
    # services.longview = {
    #   enable = true;
    #   apiKeyFile = "/var/lib/longview/apiKeyFile";
    # };

    # Install Diagnostic Tools
    environment.systemPackages = with pkgs; [
      inetutils
      mtr
      sysstat
    ];

  };

}
