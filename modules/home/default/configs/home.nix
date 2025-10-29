{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption types;
in {
  options.home.uid = mkOption {
    type = with types; nullOr int;
    default = osConfig.users.users.${config.home.username}.uid or null;
    description = ''
      Lookup uid from flake.users.<name>.uid and assign to config.home.uid
    '';
  };

  options.home.portOffset = mkOption {
    type = with types; nullOr int;
    default = let
      uid =
        if config.home.uid == null
        then 1000
        else config.home.uid;
    in
      if uid >= 1000
      then uid - 1000
      else 0;
    description = ''
      Calculated offset to be added to ports (uid - 1000)
    '';
  };

  options.home.localStorePath = lib.mkOption {
    type = with lib.types; listOf str;
    default = [];
    description = ''
      List of paths (relative to $HOME) whose Home Manager symlinks
      should be redirected to writable copies in ~/.local/store.
    '';
  };

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------
  config = {
    # Add support for ~/.local/bin
    home.sessionPath = ["$HOME/.local/bin"];

    # Additional env variables
    home.sessionVariables = {
      # Accept agreements for unfree software (when installing imperatively)
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    # Replace list of symlinks with real files
    home.activation = let
      store = "${config.home.homeDirectory}/.local/store";
      git = "${pkgs.git}/bin/git";
    in
      mkIf (config.home.localStorePath != []) {
        localStoreRemove = lib.hm.dag.entryBefore ["checkLinkTargets"] ''rm -rf "${store}"'';
        localStore =
          lib.hm.dag.entryAfter ["linkGeneration"]
          # bash
          ''
            mkdir -p "${store}"
            for rel in ${lib.concatStringsSep " " config.home.localStorePath}; do
              target="$HOME/$rel"
              if [ -L "$target" ]; then
                # Convert relative path to a flat filename: replace / with -
                writable="${store}/$(echo "$rel" | tr / -)"
                cp -f "$(readlink -f "$target")" "$writable"
                chmod -R u+w "$writable"
                ln -sf "$writable" "$target"
                echo "Redirected $target -> $writable"
              fi
            done
            # Create a repo here to ease tracking changes with git diff
            ${git} -C "${store}" init
            ${git} -C "${store}" add .
            ${git} -C "${store}" commit -m "activation"
          '';
      };
  };
}
