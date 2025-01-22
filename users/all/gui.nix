{ config, lib, ... }: {

  # Toggle gui
  options.gui.enable = lib.options.mkEnableOption "gui"; 

}
