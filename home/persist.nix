{ inputs, config, lib, ... }: 

let 
  inherit (lib) mkOption types;

in {
  
  imports = [ "${inputs.impermanence}/home-manager.nix" ];

  options = with types; {

    # Persist in /nix/state
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


    # Persist in /nix/data
    data = {

      # Files relative to ~ home
      files = mkOption {
        description = "Additional user data files to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ "hello-world.txt" ];
      };

      # Directories relative to ~ home
      dirs = mkOption {
        description = "Additional user data directories to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ "Downloads" ];
      };

    };

  };

  config = {

    # state.dirs = [ ".var" ];
    # state.files = [ ".bash_history" ];
    # data.dirs = [ "Downloads" "Desktop" ];
    data.dirs = [ "test" "test2" ];

    # Configuration impermanence module
    home.persistence = {

      # State stored on subvolume
      "/nix/state" = {
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

      # Data stored on subvolume
      "/nix/data" = {
        allowOther = true;
        files = config.data.files;
        directories = config.data.dirs;
      };

    };

  };

}
