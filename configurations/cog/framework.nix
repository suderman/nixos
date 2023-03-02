# NixOS Configuration for Framework Laptop
# https://gist.github.com/digitalknk/ee0379c1cd4597463c31a323ea5882a5
# https://community.frame.work/t/nixos-on-the-framework-blog-review/3835
{ config, lib, pkgs, modulesPath, ... }: {

  boot.kernelParams = [ "mem_sleep_default=deep" ];

  # No longer needed: current kernel is modern enough
  # boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest.override {
  #   argsOverride = rec {
  #     src = pkgs.fetchurl {
  #       url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
  #       sha256 = "1j0lnrsj5y2bsmmym8pjc5wk4wb11y336zr9gad1nmxcr0rwvz9j";
  #     };
  #     version = "5.15.1";
  #     modDirVersion = "5.15.1";
  #   };
  # });

  powerManagement = {
    enable = true;
    powertop.enable = true;
    # *conflicts with inputs.hardware.nixosModules.framework
    # cpuFreqGovernor = lib.mkDefault "ondemand";
  };

  # Enable Bluetooth
  hardware.bluetooth.enable = true;

  # Enable Networking Management
  networking.networkmanager.enable = true;

  # Enable thermal data
  services.thermald.enable = true;

  # Enable fingerprint support
  services.fprintd.enable = true;

  hardware.opengl.extraPackages = with pkgs; [
    mesa_drivers
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
    intel-media-driver
  ];

  # rtkit is optional but recommended
  security.rtkit.enable = true;

  # *conflicts with inputs.hardware.nixosModules.framework
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   # If you want to use JACK applications, uncomment this
  #   #jack.enable = true;
  #
  #   # use the example session manager (no others are packaged yet so this is enabled by default,
  #   # no need to redefine it in your config for now)
  #   #media-session.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

}
