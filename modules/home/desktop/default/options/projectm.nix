# programs.projectm.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.projectm;
  dataDir = ".config/projectM";
  visualizerDir = "Documents/Resources/Visualizer";
in {
  options.programs.projectm.enable = lib.mkEnableOption "projectm";
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.projectm-sdl-cpp];
    persist.storage.directories = [dataDir];

    xdg.desktopEntries."projectm" = {
      name = "ProjectM";
      genericName = "Music Visualizer";
      icon = "multimedia-player";
      terminal = false;
      type = "Application";
      exec = "${lib.getExe pkgs.projectm-sdl-cpp}";
    };

    # Default settings when none yet exist
    home.activation.projectm = let
      file = "${config.home.homeDirectory}/${dataDir}/projectMSDL.properties";
      properties = pkgs.writeText "projectMSDL.properties" ''
        jprojectM.enableSplash: false
        projectM.droppedFolderOverride: true
        projectM.presetLocked: false
        projectM.presetPath: ${config.home.homeDirectory}/${visualizerDir}/presets/
        projectM.texturePath: ${config.home.homeDirectory}/${visualizerDir}/textures/
        window.borderless: true
      '';
    in
      lib.hm.dag.entryAfter ["writeBoundary"]
      # bash
      ''
        $DRY_RUN_CMD mkdir -p "$(dirname ${file})"
        $DRY_RUN_CMD [[ -e ${file} ]] || cat ${properties} >${file}
      '';
  };
}
