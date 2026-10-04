# https://www.linode.com/docs/guides/install-nixos-on-linode/
{
  lib,
  pkgs,
  ...
}: {
  # Enable LISH for Linode
  boot.kernelParams = ["console=ttyS0,19200n8"];
  boot.loader.grub.extraConfig = ''
    serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
    terminal_input serial;
    terminal_output serial
  '';

  # Configure GRUB for Linode
  boot.loader.grub.enable = true;
  boot.loader.grub.forceInstall = false;
  # Disko can supply the same device at normal priority.
  boot.loader.grub.devices = lib.mkDefault ["/dev/sda"];
  boot.loader.timeout = 10;

  # Disable predictable interface names for Linode
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false; # Disable DHCP globally as we will not need it.
  networking.interfaces.eth0.useDHCP = true;

  # Preserve the legacy IPv4-only default. Verify IPv6 before relying on it.
  networking.enableIPv6 = lib.mkDefault false;

  # Install Diagnostic Tools
  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
  ];
}
