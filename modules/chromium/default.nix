{ config, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (lib) mkIf mkOption types;
  inherit (lib) hasPrefix mapAttrsToList versions;

  # # all bookmarkedExtensions collected from all users
  # bookmarkedExtensions = builtins.foldl' (acc: user: 
  #   acc // (config.home-manager.users.${user}.programs.chromium.bookmarkedExtensions or {})
  # ) {} (builtins.attrNames config.home-manager.users or {});

  extensions = builtins.foldl' (acc: user: 
    acc // (config.home-manager.users.${user}.programs.chromium.lib.extensions or {})
  ) {} (builtins.attrNames config.home-manager.users or {});

  enable = let 
    inherit (builtins) any attrNames;
    inherit (config.home-manager) users;
  in any (user: users.${user}.programs.chromium.enable or false) (attrNames users); 

in {

  options.programs.chromium = {
    package = mkOption {
      type = types.package;
      default = pkgs.ungoogled-chromium;
    };
    crxDir = mkOption {
      type = types.path;
      default = "/nix/state/crx";
    };
  };

  config = mkIf enable {

    programs.chromium = {

      # Module only writes configuration to /etc, doesn't run anything
      enable = true;

      # defaultSearchProviderEnabled = true;
      # defaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}{google:instantExtendedEnabledParameter}ie={inputEncoding}";
      # defaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";

      # Policies
      extraOpts = {

        # 5 = Open New Tab Page
        # 1 = Restore the last session
        # 4 = Open a list of URLs
        # 6 = Open a list of URLs and restore the last session
        "RestoreOnStartup" = 1;
        # "RestoreOnStartupURLs" = [];

        # 0 = Predict network actions on any network connection
        # 2 = Do not predict network actions on any network connection
        "NetworkPredictionOptions" = 0;

        "HttpsOnlyMode" = "allowed";
        "MemorySaverModeSavings" = 1;
        # "SearchSuggestEnabled" = true;
        "PasswordManagerEnabled" = false;
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [ "en-CA" ];

        "BookmarksBarEnabled" = true;
        "ManagedBookmarks" = [{ toplevel_name = "Extensions"; }] ++ map 
          (name: { inherit name; url = "file://${cfg.crxDir}/${name}/extension.crx"; }) 
          (builtins.attrNames extensions);
      };

      # The user has to confirm the installation of extensions on the first run
      # initialPrefs = {
      #   "first_run_tabs" = map url (builtins.attrValues bookmarkedExtensions);
      # };

    };

    systemd.services.crx = {
      description = "crx";
      after = [ "multi-user.target" ];
      requires = [ "multi-user.target" ];
      wantedBy = [ "sysinit.target" ];
      serviceConfig.Type = "oneshot";
      path = with pkgs; [ curl go-crx3 jq ];
      script = let

        inherit (builtins) concatStringsSep;
        inherit (lib) hasPrefix mapAttrsToList versions;

        url = id: if hasPrefix "http://" id || hasPrefix "https://" id then id else 
          "https://clients2.google.com/service/update2/crx" +
          "?response=redirect" +
          "&acceptformat=crx2,crx3" +
          "&prodversion=${versions.major cfg.package.version}" + 
          "&x=id%3D${id}%26installsource%3Dondemand%26uc";

      in ''
        # Download extension by id from URL or Google Web Store
        update() {

          # First arg is crx name, create directory
          dir="${cfg.crxDir}/$1"
          mkdir -p $dir; cd $dir

          # Second arg is crx url, download extension
          curl -sL "$2" > extension.crx || true
          crx3 unpack extension.crx || true

          # Write extension's JSON file
          printf '{"external_crx":"%s","external_version":"%s"}' \
          "$dir/extension.crx" "$(cat extension/manifest.json | jq -r .version)" \
          > $(crx3 id extension.crx).json || true

        }

      '' + concatStringsSep "\n" (mapAttrsToList ( name: id: ''
        update "${name}" "${url id}"
      '' ) extensions);

    };

    # Run this script every day
    systemd.timers.crx = {
      wantedBy = [ "timers.target" ];
      partOf = [ "crx.service" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "crx.service";
      };
    };

  };

}
