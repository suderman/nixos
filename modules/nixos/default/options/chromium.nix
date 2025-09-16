{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.chromium;
  inherit (builtins) attrNames any foldl';
  inherit (lib) mkIf mkOption types;
  users = config.home-manager.users or {};

  # All enabled extensions from all home-manager users
  extensions = foldl' (acc: user: let
    cfg = users.${user}.programs.chromium or {};
    exts = (cfg.externalExtensions or {}) // (cfg.unpackedExtensions or {});
  in
    acc // exts) {} (attrNames users);

  # If any home-manager chromium is enabled for any user, set this to true
  enable = any (user: users.${user}.programs.chromium.enable or false) (attrNames users);
in {
  options.programs.chromium = {
    package = mkOption {
      description = "My preferred flavor of chromium is ungoogled-chromium";
      type = types.package;
      default = pkgs.ungoogled-chromium;
    };
    crxDir = mkOption {
      description = "Path to directory where extensions are loaded from";
      type = types.path;
      default = "/mnt/main/storage/crx";
    };
  };

  # Only enable the nixos module if the home-manager module is enabled
  config = mkIf enable {
    # nixos module enables managed policies written to /etc
    programs.chromium = {
      enable = true;
      extraOpts = {
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "Startpage";
        DefaultSearchProviderKeyword = "@start";
        DefaultSearchProviderSearchURL = "https://www.startpage.com/sp/search?query={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://www.startpage.com/suggestions?query={searchTerms}";
        DefaultSearchProviderIconURL = "https://www.startpage.com/favicon.ico";
        DefaultSearchProviderEncodings = ["UTF-8"];
        SearchSuggestEnabled = true;
        # SearchEngines = [{
        #   Name = "Startpage";
        #   Keyword = "@start";
        #   URL = "https://www.startpage.com/sp/search?query={searchTerms}";
        #   FaviconURL = "https://www.startpage.com/favicon.ico";
        #   Encoding = "UTF-8";
        # } {
        #   Name = "Nix Code";
        #   Keyword = "@nix";
        #   URL = "https://github.com/search?type=code&q=lang%3Anix+{searchTerms}";
        #   FaviconURL = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #   Encoding = "UTF-8";
        # }];
        BrowserAddPersonEnabled = false; # Disable user profiles
        BrowserGuestModeEnabled = false; # Disable guest mode
        BuiltInDnsClientEnabled = false;
        ShowFullUrlsInAddressBar = true;
        DeveloperToolsAvailability = 1;
        RestoreOnStartup = 1; # restore last session
        NetworkPredictionOptions = 0;
        HttpsOnlyMode = "allowed";
        MemorySaverModeSavings = 1;
        PasswordManagerEnabled = false;
        SpellcheckEnabled = true;
        SpellcheckLanguage = ["en-CA"];
        BookmarksBarEnabled = true;
        ManagedBookmarks =
          [{toplevel_name = "Extensions";}]
          ++ map
          (name: {
            inherit name;
            url = "file://${cfg.crxDir}/${name}/extension.crx";
          })
          (builtins.attrNames extensions);
      };

      # Open these tabs on a first run of a new installation
      initialPrefs = {
        # first_run_tabs = "";
      };
    };

    # Downloads extensions found in home-manager and builds expected json for each
    systemd.services.crx = {
      description = "crx";
      after = ["multi-user.target"];
      requires = ["multi-user.target"];
      wantedBy = ["sysinit.target"];
      serviceConfig.Type = "oneshot";
      path = with pkgs; [curl go-crx3 jq];
      script = let
        inherit (builtins) concatStringsSep;
        inherit (lib) hasPrefix mapAttrsToList versions;

        # Convert an extension id to a download url (if it isn't a url already)
        url = id:
          if hasPrefix "http://" id || hasPrefix "https://" id
          then id
          else
            "https://clients2.google.com/service/update2/crx"
            + "?response=redirect"
            + "&acceptformat=crx2,crx3"
            + "&prodversion=${versions.major cfg.package.version}"
            + "&x=id%3D${id}%26installsource%3Dondemand%26uc";
      in
        ''
          # Download extension by id from URL or Google Web Store
          update() {

            # First arg is crx name, create directory
            dir="${cfg.crxDir}/$1"
            mkdir -p $dir; cd $dir

            # Second arg is crx url, download extension and validate id
            curl -sL "$2" > .extension.crx || true
            if [[ "$(crx3 id .extension.crx 2>/dev/null)" =~ ^[a-p]{32}$ ]]; then

              # If valid, rename tmp file and unpack
              mv .extension.crx extension.crx
              crx3 unpack extension.crx || true

              # Write extension's JSON file
              printf '{"external_crx":"%s","external_version":"%s"}' \
              "$dir/extension.crx" "$(cat extension/manifest.json | jq -r .version)" \
              > $(crx3 id extension.crx).json || true

            # If invalid download, delete tmp file
            else
              rm .extension.crx
            fi

          }

        ''
        + concatStringsSep "\n" (mapAttrsToList (name: id: ''
            update ${name} \
            "${url id}"
          '')
          extensions)
        + ''

          # Trigger user services to symlink extensions
          date > ${cfg.crxDir}/last
        '';
    };

    # Run this script every day
    systemd.timers.crx = {
      wantedBy = ["timers.target"];
      partOf = ["crx.service"];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "crx.service";
      };
    };
  };
}
