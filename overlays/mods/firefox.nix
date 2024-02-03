{ final, prev, ... }: let

  inherit (prev) lib this;
  inherit (this.lib) appId;

# Enable policies and import personal Certificate Authority
in prev.firefox.override {
  extraPolicies = {
    DontCheckDefaultBrowser = true;
    DisablePocket = true;
    DisableFirefoxStudies = true;

    Certificates = { ImportEnterpriseRoots = true; Install = [ this.ca ]; };
    
    # SearchEngines = {
    #   Add = [
    #     {
    #       Name = "Whoogle";
    #       URLTemplate = "https://g.sol/search?q={searchTerms}";
    #       Method = "POST";
    #       IconURL = "https://g.sol/static/img/favicon/apple-icon-144x144.png";
    #       Alias = "whoogle";
    #     }
    #   ];
    #   Default = "Whoogle";
    #   Remove = [ "Bing" "Amazon" "Wikipedia (en)" ];
    # };

  };
} 
