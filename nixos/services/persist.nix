{ inputs, config, lib, ... }: 

let 
  inherit (lib) mkOption types;

in {
  
  imports = [ inputs.impermanence.nixosModule ];

  # state.dirs = [ '/var/lib' ];
  # state.user.dirs = [ '.local/share' ];
  # data.dirs = [ '/data' ];
  # data.user.dirs = [ 'Documents' ];

  options = with types; {

    # Persist in /nix/state
    state = {

      # Files relative to / root
      files = mkOption {
        description = "Additional system state files to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ "/etc/machine-id" ];
      };

      # Directories relative to / root
      dirs = mkOption {
        description = "Additional system state directories to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ "/etc/nixos" ];
      };

      # user = {
      #
      #   # Files relative to ~ home
      #   files = mkOption {
      #     description = "Additional user state files to preserve";
      #     type = listOf (either str attrs);
      #     default = [];
      #     example = [ ".bash_history" ];
      #   };
      #
      #   # Directories relative to ~ home
      #   dirs = mkOption {
      #     description = "Additional user state directories to preserve";
      #     type = listOf (either str attrs);
      #     default = [];
      #     example = [ ".var" ];
      #   };
      #
      # };

    };


    # Persist in /nix/data
    data = {

      # Files relative to / root
      files = mkOption {
        description = "Additional system data files to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ "/hello-world.txt" ];
      };

      # Directories relative to / root
      dirs = mkOption {
        description = "Additional system data directories to preserve";
        type = listOf (either str attrs);
        default = [];
        example = [ "/backup" ];
      };

      # user = {
      #
      #   # Files relative to ~ home
      #   files = mkOption {
      #     description = "Additional user data files to preserve";
      #     type = listOf (either str attrs);
      #     default = [];
      #     example = [ "hello-world.txt" ];
      #   };
      #
      #   # Directories relative to ~ home
      #   dirs = mkOption {
      #     description = "Additional user data directories to preserve";
      #     type = listOf (either str attrs);
      #     default = [];
      #     example = [ "Downloads" ];
      #   };
      #
      # };

    };

  };

  config = {

    # state.files = [ "/etc/machine-id" ];
    # state.dirs = [ "/etc/nixos" ];
    # state.user.dirs = [ ".var" ];
    # state.user.files = [ ".bash_history" ];
    #
    # data.dirs = [ "/data" ];
    # data.user.dirs = [ "Downloads" "Desktop" ];

    state.dirs = [ "/s_test" ];
    data.dirs = [ "/d_test" "/srv/nested/folder" ];

    # Configuration impermanence module
    environment.persistence = {

      # State stored on subvolume
      "/nix/state" = {
        hideMounts = true;

        files = [ 
          # "/etc/machine-id"           # default: machine identification
        ] ++ config.state.files;

        directories = [
          # "/etc/nixos"                # default: nixos configuration
          # "/var/log"                  # default: logs
          # "/var/lib/AccountsService"  # possibly move this to gnome.nix?
        ] ++ config.state.dirs;

        # users.me.files = [
        #   ".nix-channels"
        #   ".bash_history"
        #   ".zsh_history"
        # ] ++ config.user.state.files;
        #
        # users.me.directories = [
        #   ".local/share/Trash"
        #   { directory = ".local/share/keyrings"; mode = "0700"; }
        # ] ++ config.user.state.dirs;

      };

      # Data stored on subvolume
      "/nix/data" = {
        hideMounts = true;
        files = config.data.files;
        directories = config.data.dirs;
      };

    };

    #
    # environment.persistence."/nix/data" = {
    #   hideMounts = true;
    #   users.me = {
    #     files = [
    #       ".nix-channels"
    #       ".bash_history"
    #       ".zsh_history"
    #     ] ++ config.user.persist.files;
    #     directories = [
    #       ".local/share/Trash"
    #       { directory = ".local/share/keyrings"; mode = "0700"; }
    #     ] ++ config.user.persist.dirs;
    #   };
    # };

    # Allows users to allow others on their binds
    programs.fuse.userAllowOther = true;


  };


}
