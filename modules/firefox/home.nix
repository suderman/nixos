# modules.firefox.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.firefox;
  inherit (lib) mkIf;

in {

  options.modules.firefox = {
    enable = lib.options.mkEnableOption "firefox"; 
  };

  config = mkIf cfg.enable {

    # programs.firefox = {
    #   enable = true;
    #
    #   # package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    #   #   extraPolicies = {
    #   #     DisableFirefoxStudies = true;
    #   #     DisablePocket = true;
    #   #     DisableTelemetry = true;
    #   #     DisableSetDesktopBackground = true;
    #   #     DontCheckDefaultBrowser = true;
    #   #     Certificates = { ImportEnterpriseRoots = true; Install = [ this.ca ]; };
    #   #   };
    #   # };
    #
    #   profiles = {};
    #
    # };

  };
}
