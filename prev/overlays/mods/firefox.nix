{ final, prev, ... }: let

  inherit (prev) lib this;

# Enable policies and import personal Certificate Authority
in prev.firefox.override {
  extraPolicies = {
    DontCheckDefaultBrowser = true;
    DisablePocket = true;
    DisableFirefoxStudies = true;
    Certificates = { ImportEnterpriseRoots = true; Install = [ this.ca ]; };
  };
} 
