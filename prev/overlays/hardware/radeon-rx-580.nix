# AMD Radeon RX 580 8GB
{ config, pkgs, lib, hardware, ... }: {

  # https://github.com/NixOS/nixos-hardware/tree/master/common/gpu/amd
  imports = [ hardware.common-gpu-amd ];

  # LTS kernel
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ libvdpau-va-gl vaapiVdpau ];
    extraPackages32 = with pkgs; [ libvdpau-va-gl vaapiVdpau ];
  };

  # rocm-smi
  environment.systemPackages = [ pkgs.rocmPackages.rocm-smi ];
  
  # rocm-smi included in monitoring
  services.beszel.extraPackages = [ pkgs.rocmPackages.rocm-smi ];

  # https://wiki.nixos.org/wiki/AMD_GPU
  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1";
  };

  file."/opt/rocm/hip" = { 
    type = "link"; 
    source = "${pkgs.rocmPackages.clr}";
  };

}
