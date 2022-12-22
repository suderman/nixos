{ inputs, config, lib, ... }: 

let 
  inherit (lib) mkOption types;

in {
  
  imports = [ "${inputs.impermanence}/home-manager.nix" ];

  options = with types; {

    # Persist in /nix/home
    state = {

      # Files relative to ~ home
      files = mkOption {
        description = "Additional user state files to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ ".bash_history" ];
      };

      # Directories relative to ~ home
      dirs = mkOption {
        description = "Additional user state directories to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ ".var" ];
      };

    };

  };

  config = {

    # state.files = [ ".bash_history" ];
    # state.dirs = [ "Downloads" "Desktop" ];

    # Configuration impermanence module
    home.persistence = {

      # State stored on subvolume
      "/nix/home" = {
        allowOther = true;

        files = [
          # ".nix-channels"
          # ".bash_history"
          # ".zsh_history"
        ] ++ config.state.files;

        directories = [
          # ".local/share/Trash"
          # ".local/share/keyrings"
        ] ++ config.state.dirs;

      };

    };

  };

}
