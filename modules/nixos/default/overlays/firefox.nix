{flake, ...}: {
  nixpkgs.overlays = [
    (_final: prev: {
      # Enable policies and import personal Certificate Authority
      firefox = prev.firefox.override {
        extraPolicies = {
          DontCheckDefaultBrowser = true;
          DisablePocket = true;
          DisableFirefoxStudies = true;
          Certificates = {
            ImportEnterpriseRoots = true;
            Install = [flake.networking.ca];
          };
        };
      };
    })
  ];
}
