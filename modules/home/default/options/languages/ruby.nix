{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.ruby;
  gemDir = ".local/share/gem";
in {
  options.programs.ruby.enable = lib.mkEnableOption "ruby";

  config = lib.mkIf cfg.enable {
    persist.scratch.directories = [gemDir];

    home.sessionVariables = rec {
      GEM_HOME = "${config.home.homeDirectory}/${gemDir}";
      GEM_PATH = GEM_HOME;
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/${gemDir}/bin"
    ];

    home.packages = [
      pkgs.ruby # ruby ri bundle bunlder erb gem irb rake rdoc
    ];
  };
}
