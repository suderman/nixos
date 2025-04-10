{ config, lib, pkgs, ... }: let

  cfg = config.programs.chromium;
  inherit (lib) mkIf mkOption types;

  hash = "/nix/state/chromium-config.hash";

  chromeWebstoreCrxUrl = id: "https://clients2.google.com/service/update2/crx"
    + "?response=redirect"
    + "&acceptformat=crx2,crx3"
    + "&prodversion=${cfg.package.version}"
    + "&x=id%3D${id}%26uc";

  # # ublock policies as an attr set, reusable from firefox, that's why it's a seperate module.
  # ublockPolicies = import ./ublock-policies.nix {};

in {

  options.programs.chromium.package = mkOption {
    type = types.package;
    default = pkgs.ungoogled-chromium;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    programs.chromium = {

      # Extensions
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        "doojmbjmlfjjnbmnoijecmcbfeoakpjm" # noscript
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1password
        "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock
        # "dbepggeogbaibhgnhhndojpepiihcmeb" # vimium
      ];

      defaultSearchProviderEnabled = true;
      defaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}{google:instantExtendedEnabledParameter}ie={inputEncoding}";
      defaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";

      # Policies
      extraOpts = {
        ExtensionSettings =
          # allow added extensions
          (builtins.listToAttrs ( map
              (ext: {
                name = ext;
                value = { 
                  installation_mode = "allowed"; 
                  update_url = "https://clients2.google.com/service/update2/crx";
                };
              })
              ( config.programs.chromium.extensions ++ [
                "ocaahdebbfolfmndjeplogmgcagdmblk" # chromium web store
                # "oladmjdebphlnjjcnomfhhbfdldiimaf" # libredirect
              ])
          )) // {
            # "*" = {
            #   installation_mode = "blocked"; # Block by default
            #   blocked_install_message = "Add in nixos module!";
            # };
            "*" = {
              installation_mode = "allowed"; # allow by default
            };

            "ocaahdebbfolfmndjeplogmgcagdmblk" = {
              installation_mode = "allowed";
              update_url = "https://github.com/NeverDecaf/chromium-web-store/releases/latest/download/Chromium.Web.Store.crx";
            };

            # Pin ublock
            "cjpalhdlnbpafiamejdnhcphjbkeiagm" = {
              # installation_mode = "allowed";
              installation_mode = "allowed";
              update_url = "https://clients2.google.com/service/update2/crx";
              toolbar_pin = "force_pinned";
            };

            # Pin 1password
            "aeblfdkhhhdcdjpifhhbdiojplfjncoa" = {
              # installation_mode = "allowed";
              installation_mode = "allowed";
              update_url = "https://clients2.google.com/service/update2/crx";
              toolbar_pin = "force_pinned";
            };
          };

        # "3rdparty" = {
        #   "extensions" = {
        #     "cjpalhdlnbpafiamejdnhcphjbkeiagm" = {
        #       adminSettings = builtins.toJSON ublockPolicies;
        #     };
        #   };
        # };

        # 5 = Open New Tab Page
        # 1 = Restore the last session
        # 4 = Open a list of URLs
        # 6 = Open a list of URLs and restore the last session
        "RestoreOnStartup" = 1;
        # "RestoreOnStartupURLs" = [];

        # 0 = Predict network actions on any network connection
        # 2 = Do not predict network actions on any network connection
        "NetworkPredictionOptions" = 0;

        "HttpsOnlyMode" = "force_enabled";
        "MemorySaverModeSavings" = 1;
        "SearchSuggestEnabled" = true;
        "PasswordManagerEnabled" = false;
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [ "en-US" ];
      };

      # The user has to confirm the installation of extensions on the first run
      initialPrefs = {
        "first_run_tabs" = (map chromeWebstoreCrxUrl config.programs.chromium.extensions) ++ [
          "https://github.com/NeverDecaf/chromium-web-store/releases/latest/download/Chromium.Web.Store.crx"
          # "https://github.com/libredirect/browser_extension/releases/download/v3.1.0/libredirect-3.1.0.crx"
        ];
      };
    };

    # nixpkgs.overlays = [
    #   (self: super: {
    #     ungoogled-chromium = (
    #       super.ungoogled-chromium.override {
    #         commandLineArgs = [
    #           "--enable-incognito-themes"
    #           "--extension-mime-request-handling=always-prompt-for-install"
    #           "--fingerprinting-canvas-image-data-noise"
    #           "--fingerprinting-canvas-measuretext-noise"
    #           "--fingerprinting-client-rects-noise"
    #           "--disable-smooth-scrolling"
    #           "--enable-features=EnableFingerprintingProtectionFilter:activation_level/enabled/enable_console_logging/true,EnableFingerprintingProtectionFilterInIncognito:activation_level/enabled/enable_console_logging/true,TabstripDeclutter,DevToolsPrivacyUI,ImprovedSettingsUIOnDesktop,MultiTabOrganization,OneTimePermission,TabOrganization,TabOrganizationSettingsVisibility,TabReorganization,TabReorganizationDivider,TabSearchPositionSetting,TabstripDedupe,TaskManagerDesktopRefresh"
    #           "--disable-features=EnableTabMuting"
    #         ];
    #       }
    #     );
    #   })
    # ];

    systemd.services.deleteChromiumFirstRun = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        if ! systemctl is-system-running --quiet; then
          echo "system is not fully running yet. skipping chromium update check."
          exit 0
        fi
         echo "checking if chromium hash changed..."
         # configuration hash storage location, might need to be updated to some persistent location on your computer
         CHROMIUM_HASH_FILE="${hash}"
         CURRENT_HASH="${
           builtins.hashString "sha256" (
             (builtins.toJSON cfg.extensions)
             + (builtins.toJSON cfg.extraOpts.ExtensionSettings)
             + (builtins.toJSON cfg.initialPrefs)
           )
         }"
         echo $CURRENT_HASH

         if [ -f "$CHROMIUM_HASH_FILE" ]; then
           STORED_HASH=$(cat "$CHROMIUM_HASH_FILE")
           if [ "$STORED_HASH" = "$CURRENT_HASH" ]; then
             echo "chromium hash unchanged, skipping deletion of 'First Run' files."
             exit 0
           fi
         fi

         echo "chromium hash changed, deleting 'First Run' files..."
         for i in /home/*; do
           if [ -f "$i/.config/chromium/First Run" ]; then
             echo "Deleting '$i/.config/chromium/First Run'"
             rm -f "$i/.config/chromium/First Run"
           fi
         done

         echo "$CURRENT_HASH" > "$CHROMIUM_HASH_FILE"
      '';
    };
  };

}
